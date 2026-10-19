#!/bin/sh
set -eu
pkg install -y git python313 php85
# OPNsense pins Python 3.13 while FreeBSD's default Python flavor may move ahead.
# Trust anchor: opnsense/core stable/26.7, src/etc/pkg/fingerprints/OPNsense/trusted/.
TRUST=/tmp/opnsense-build-trust
mkdir -p "$TRUST/trusted" "$TRUST/revoked"
cp tools/release/trust/pkg.opnsense.org.20260608 "$TRUST/trusted/"
cat > /usr/local/etc/pkg/repos/OPNsenseBuild.conf <<'EOF'
OPNsenseBuild: {
  url: "https://pkg.opnsense.org/${ABI}/26.7/latest",
  fingerprints: "/tmp/opnsense-build-trust",
  signature_type: "fingerprints",
  enabled: yes
}
EOF
pkg install -y -r OPNsenseBuild py313-pyyaml
