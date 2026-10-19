#!/bin/sh
# Bootstrap the Opnwall catalog trust anchor; no plugin is installed automatically.
set -eu
[ "$(id -u)" -eq 0 ] || { echo 'Run as root on OPNsense' >&2; exit 1; }
[ "$(uname -s)" = FreeBSD ] || { echo 'OPNsense/FreeBSD is required' >&2; exit 1; }
SERIES=$(opnsense-version -a)
ABI=$(pkg config ABI)
case "$SERIES" in ''|*[!0-9.]*) exit 1;; esac
case "$ABI" in ''|*[!A-Za-z0-9:_-]*) exit 1;; esac
BASE=https://raw.githubusercontent.com/Opnwall/OPNsense-Firewall-Map/packages
PUBKEY=/usr/local/etc/pkg/keys/opnwall-dashboard-plus.pub
CONF=/usr/local/etc/pkg/repos/opnwall-dashboard-plus.conf
EXPECTED=5a016623073d35afbaac96c9d97081e3f9bc7d0ff2a4b2c20aed7390936a2a31
TMP=$(mktemp -d /tmp/opnwall-dashboard-repo.XXXXXX)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
fetch -qo "$TMP/public.key" "$BASE/keys/opnwall-dashboard-plus.pub"
[ "$(sha256 -q "$TMP/public.key")" = "$EXPECTED" ] || { echo 'Public key fingerprint mismatch' >&2; exit 1; }
openssl pkey -pubin -in "$TMP/public.key" -noout
# Refuse configuration for a release/ABI without a published feed.
fetch -qo "$TMP/meta.conf" "$BASE/repo/$SERIES/$ABI/meta.conf"
mkdir -p /usr/local/etc/pkg/keys /usr/local/etc/pkg/repos
STAMP=$(date +%Y%m%d-%H%M%S)
[ ! -f "$CONF" ] || cp -p "$CONF" "$CONF.bak.$STAMP"
[ ! -f "$PUBKEY" ] || cp -p "$PUBKEY" "$PUBKEY.bak.$STAMP"
install -o root -g wheel -m 644 "$TMP/public.key" "$PUBKEY"
cat > "$TMP/repo.conf" <<EOF
OpnwallDashboardPlus: {
  url: "$BASE/repo/$SERIES/\${ABI}",
  mirror_type: "none",
  signature_type: "pubkey",
  pubkey: "$PUBKEY",
  priority: 30,
  enabled: yes
}
EOF
install -o root -g wheel -m 644 "$TMP/repo.conf" "$CONF"
pkg update -f -r OpnwallDashboardPlus
echo 'Opnwall signed repository configured. Existing repositories were preserved.'
echo 'Review packages with: pkg upgrade -n -r OpnwallDashboardPlus'
