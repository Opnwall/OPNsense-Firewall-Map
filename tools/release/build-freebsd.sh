#!/bin/sh
set -eu
[ "$(uname -s)" = FreeBSD ]
[ "$(uname -m)" = amd64 ]
ROOT=$(pwd)
git config --global --add safe.directory "$ROOT"
FRAMEWORK=/tmp/opnsense-release-framework
FRAMEWORK_COMMIT=5ac2959c8514b4f60e94d65439be5f629f10521f
# Pin the exact framework instead of silently falling back to master.
git clone -q https://github.com/opnsense/plugins.git "$FRAMEWORK"
git -C "$FRAMEWORK" checkout -q "$FRAMEWORK_COMMIT"
mkdir -p "$FRAMEWORK/security/firewall-map"
# Export tracked source only; node_modules, bytecode and local files cannot ship.
git archive HEAD security/firewall-map > /tmp/firewall-map-release-source.tar
tar -xf /tmp/firewall-map-release-source.tar -C "$FRAMEWORK"
P="$FRAMEWORK/security/firewall-map"
mkdir -p "$P/src/libexec"
cc -O2 -Wall -Wextra -Werror -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIE \
    -I"$P/collector" "$P"/collector/*.c -lm -pie -Wl,-z,relro -Wl,-z,now \
    -o "$P/src/libexec/firewallmap-collector"
chmod 755 "$P/src/libexec/firewallmap-collector"
(cd "$P" && make PLUGIN_PYTHON=313 PLUGIN_PHP=85 PLUGIN_ABI=26.7 PLUGIN_HASH="$(git -C "$ROOT" rev-parse HEAD)" package)
mkdir -p dist
cp "$P"/work/pkg/*.pkg dist/
PKG=$(find dist -name 'os-firewall-map-*.pkg')
[ "$(pkg query -F "$PKG" %n)" = os-firewall-map ]
[ "$(pkg query -F "$PKG" %q)" = FreeBSD:15:amd64 ]
if pkg info -lF "$PKG" | grep -E '(__pycache__|\.pyc$|\.DS_Store|/\._)'; then exit 1; fi
python3.13 tools/release/metadata.py bundle dist
# All PHP sources are parsed without installing or executing the plugin.
find "$P/src" -name '*.php' -exec php -l {} \;
