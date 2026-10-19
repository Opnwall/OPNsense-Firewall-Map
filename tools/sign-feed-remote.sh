#!/bin/sh
# Sign a complete feed with a temporary FreeBSD build host; keep the private key local.
# Usage: KEY=... tools/sign-feed-remote.sh <packages checkout> root@builder package.pkg [...]
set -eu
umask 077
FEED=${1:?packages checkout required}
HOST=${2:?FreeBSD signing host required}
shift 2
[ "$#" -gt 0 ] || { echo 'At least one package is required' >&2; exit 2; }
KEY=${KEY:-"$HOME/.local/share/opnwall/dashboard-plus/repository.key"}
SERIES=${SERIES:-26.7}
ABI=${ABI:-FreeBSD:15:amd64}
case "$SERIES" in ''|*[!0-9.]*) echo 'Invalid series' >&2; exit 2;; esac
case "$ABI" in ''|*[!A-Za-z0-9:_-]*) echo 'Invalid ABI' >&2; exit 2;; esac
[ -f "$KEY" ] || { echo 'Signing key not found' >&2; exit 1; }
PUBLIC="$FEED/keys/opnwall-dashboard-plus.pub"
EXPECTED=$(openssl pkey -in "$KEY" -pubout 2>/dev/null | shasum -a 256 | cut -d ' ' -f 1)
ACTUAL=$(shasum -a 256 "$PUBLIC" | cut -d ' ' -f 1)
[ "$EXPECTED" = "$ACTUAL" ] || { echo 'Private key does not match feed public key' >&2; exit 1; }
REMOTE=$(ssh "$HOST" 'umask 077; mktemp -d /root/opnwall-feed-sign.XXXXXX')
case "$REMOTE" in /root/opnwall-feed-sign.*) ;; *) echo 'Unexpected remote temporary directory' >&2; exit 1;; esac
cleanup() {
    ssh "$HOST" sh -s -- "$REMOTE" <<'CLEAN' || true
case "$1" in /root/opnwall-feed-sign.*) rm -rf -- "$1";; esac
CLEAN
}
trap cleanup EXIT HUP INT TERM
ssh "$HOST" "mkdir -m 700 $REMOTE/repo"
DIR="$FEED/repo/$SERIES/$ABI"
mkdir -p "$DIR"
# Retain every other package in this ABI's feed. Later arguments replace the same filenames.
for PACKAGE in "$DIR"/os-*.pkg "$@"; do
    [ -f "$PACKAGE" ] || continue
    scp "$PACKAGE" "$HOST:$REMOTE/repo/"
done
scp "$KEY" "$HOST:$REMOTE/repository.key"
ssh "$HOST" sh -s -- "$REMOTE" "$ABI" <<'SIGN'
set -eu
STAGE=$1
EXPECTED_ABI=$2
trap 'rm -f "$STAGE/repository.key"' EXIT HUP INT TERM
chmod 600 "$STAGE/repository.key"
for PACKAGE in "$STAGE"/repo/os-*.pkg; do
    NAME=$(pkg query -F "$PACKAGE" %n)
    case "$NAME" in *-devel) echo 'Development package refused' >&2; exit 1;; esac
    [ "$(pkg query -F "$PACKAGE" %q)" = "$EXPECTED_ABI" ] || { echo 'ABI mismatch' >&2; exit 1; }
done
# Keep only the newest version of each package before catalog generation.
for PACKAGE in "$STAGE"/repo/os-*.pkg; do
    [ -f "$PACKAGE" ] || continue
    NAME=$(pkg query -F "$PACKAGE" %n)
    VERSION=$(pkg query -F "$PACKAGE" %v)
    for OTHER in "$STAGE"/repo/os-*.pkg; do
        [ -f "$OTHER" ] || continue
        [ "$OTHER" != "$PACKAGE" ] || continue
        [ "$(pkg query -F "$OTHER" %n)" = "$NAME" ] || continue
        if [ "$(pkg version -t "$(pkg query -F "$OTHER" %v)" "$VERSION")" = '<' ]; then
            rm -f "$OTHER"
        fi
    done
done
pkg repo "$STAGE/repo" "rsa:$STAGE/repository.key"
for NAME in packagesite data; do cp "$STAGE/repo/$NAME.pkg" "$STAGE/repo/$NAME.tzst"; done
SIGN
scp -r "$HOST:$REMOTE/repo/." "$DIR/"
echo "Signed catalog downloaded to $DIR; publish the packages branch after verification."
