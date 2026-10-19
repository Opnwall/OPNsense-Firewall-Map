#!/bin/sh
set -eu
umask 077
git config --global --add safe.directory "$(pwd)/_feed"
# Secrets never enter the workspace, catalog, artifacts or caches.
KEY=$(mktemp /tmp/opnwall-release-key.XXXXXX)
VERIFY=$(mktemp -d /tmp/opnwall-repo-verify.XXXXXX)
cleanup() { rm -f "$KEY"; rm -rf "$VERIFY"; }
trap cleanup EXIT HUP INT TERM
printf '%s\n' "$PKG_SIGNING_KEY" > "$KEY"
unset PKG_SIGNING_KEY
openssl pkey -in "$KEY" -pubout > "$VERIFY/public.pem" 2>/dev/null
cmp "$VERIFY/public.pem" _feed/keys/opnwall-dashboard-plus.pub
export SERIES=26.7 ABI=FreeBSD:15:amd64 KEY
sh tools/publish.sh _feed dist/os-firewall-map-*.pkg
# Verify using the device's actual trust model and an isolated pkg database.
mkdir -p "$VERIFY/repos" "$VERIFY/db" "$VERIFY/cache"
cat > "$VERIFY/repos/opnwall.conf" <<EOF
OpnwallDashboardPlus: {
 url: "file://$(pwd)/_feed/repo/26.7/FreeBSD:15:amd64",
 enabled: yes,
 signature_type: "pubkey",
 pubkey: "$VERIFY/public.pem"
}
EOF
pkg -o PKG_DBDIR="$VERIFY/db" -o PKG_CACHEDIR="$VERIFY/cache" -R "$VERIFY/repos" update -f -r OpnwallDashboardPlus
# A wrong key must be rejected; do not trust an exit failure with no signature error.
openssl genrsa -out "$VERIFY/wrong.key" 2048 2>/dev/null
openssl rsa -in "$VERIFY/wrong.key" -pubout -out "$VERIFY/public.pem" 2>/dev/null
rm -rf "$VERIFY/db"
mkdir "$VERIFY/db"
if pkg -o PKG_DBDIR="$VERIFY/db" -o PKG_CACHEDIR="$VERIFY/cache" -R "$VERIFY/repos" update -f -r OpnwallDashboardPlus > "$VERIFY/wrong.log" 2>&1; then
    echo 'Wrong-key verification unexpectedly succeeded' >&2; exit 1
fi
grep -Ei 'signature|verification' "$VERIFY/wrong.log" > /dev/null
mkdir -p signed
cp -R _feed/repo signed/
cp dist/os-firewall-map-*.pkg dist/SHA256SUMS dist/RELEASE_NOTES.md dist/release.json signed/
# Preserve the feed base for optimistic locking at publication.
git -C _feed rev-parse HEAD > signed/feed-base.txt
