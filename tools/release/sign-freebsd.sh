#!/bin/sh
set -eu
umask 077
git config --global --add safe.directory "$(pwd)/_feed"
# Secrets never enter the workspace, catalog, artifacts or caches.
KEY=$(mktemp /tmp/opnwall-release-key.XXXXXX)
VERIFY=$(mktemp -d /tmp/opnwall-repo-verify.XXXXXX)
cleanup() {
    if [ -n "${SERVER_PID:-}" ]; then kill "$SERVER_PID" 2>/dev/null || true; wait "$SERVER_PID" 2>/dev/null || true; fi
    rm -f "$KEY"; rm -rf "$VERIFY"
}
trap cleanup EXIT HUP INT TERM
printf '%s\n' "$PKG_SIGNING_KEY" > "$KEY"
unset PKG_SIGNING_KEY
openssl pkey -in "$KEY" -pubout > "$VERIFY/public.pem" 2>/dev/null
cmp "$VERIFY/public.pem" _feed/keys/opnwall-dashboard-plus.pub
export SERIES=26.7 KEY
sh tools/publish.sh _feed dist/os-firewall-map-*.pkg
# Verify over loopback HTTP with isolated databases, as clients use network catalogs.
python3.13 -m http.server 8765 --bind 127.0.0.1 --directory "_feed/repo/26.7/FreeBSD:15:amd64" > "$VERIFY/http.log" 2>&1 &
SERVER_PID=$!
for attempt in 1 2 3 4 5 6 7 8 9 10; do
    if fetch -qo /dev/null http://127.0.0.1:8765/meta.conf 2>/dev/null; then break; fi
    sleep 1
done
fetch -qo /dev/null http://127.0.0.1:8765/meta.conf
mkdir -p "$VERIFY/repos" "$VERIFY/db" "$VERIFY/cache"
cat > "$VERIFY/repos/opnwall.conf" <<EOF
OpnwallDashboardPlus: {
 url: "http://127.0.0.1:8765",
 enabled: yes,
 signature_type: "pubkey",
 pubkey: "$VERIFY/public.pem"
}
EOF
pkg -o PKG_DBDIR="$VERIFY/db" -o PKG_CACHEDIR="$VERIFY/cache" -R "$VERIFY/repos" update -f -r OpnwallDashboardPlus
EXPECTED=$(pkg query -F dist/os-firewall-map-*.pkg '%n-%v')
ACTUAL=$(pkg -o PKG_DBDIR="$VERIFY/db" -o PKG_CACHEDIR="$VERIFY/cache" -R "$VERIFY/repos" rquery -r OpnwallDashboardPlus '%n-%v' os-firewall-map)
[ "$ACTUAL" = "$EXPECTED" ]
# A wrong key must be rejected; do not trust an exit failure with no signature error.
openssl genrsa -out "$VERIFY/wrong.key" 2048 2>/dev/null
openssl rsa -in "$VERIFY/wrong.key" -pubout -out "$VERIFY/wrong.pem" 2>/dev/null
sed "s@public.pem@wrong.pem@" "$VERIFY/repos/opnwall.conf" > "$VERIFY/repos/wrong.tmp"
mv "$VERIFY/repos/wrong.tmp" "$VERIFY/repos/opnwall.conf"
mkdir "$VERIFY/wrong-db" "$VERIFY/wrong-cache"
# pkg 2.8.x can exit zero after rejecting a signature during catalog fallback.
# Require an explicit verification error AND no queryable catalog, not an exit code alone.
if pkg -o PKG_DBDIR="$VERIFY/wrong-db" -o PKG_CACHEDIR="$VERIFY/wrong-cache" -R "$VERIFY/repos" update -f -r OpnwallDashboardPlus > "$VERIFY/wrong.log" 2>&1; then :; fi
grep -Ei 'signature.*(fail|invalid)|invalid signature|verification fail' "$VERIFY/wrong.log" > /dev/null
if pkg -o PKG_DBDIR="$VERIFY/wrong-db" -o PKG_CACHEDIR="$VERIFY/wrong-cache" -R "$VERIFY/repos" rquery -r OpnwallDashboardPlus '%n' os-firewall-map > "$VERIFY/wrong-query" 2>/dev/null; then :; fi
[ ! -s "$VERIFY/wrong-query" ] || { echo 'Wrong key produced a usable catalog' >&2; exit 1; }
echo 'Wrong key rejected; no usable package catalog'
mkdir -p signed
cp -R _feed/repo signed/
cp dist/os-firewall-map-*.pkg dist/SHA256SUMS dist/RELEASE_NOTES.md dist/release.json signed/
# Preserve the feed base for optimistic locking at publication.
git -C _feed rev-parse HEAD > signed/feed-base.txt
