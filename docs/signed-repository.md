# Signed Opnwall pkg feed

The `packages` branch is a separate signed package feed. It contains only public trust
material, package archives, catalog archives, and a bootstrap installer. Source lives on
`main`. The current feed targets OPNsense 26.7 / FreeBSD:15:amd64.

## Device setup

Download and review `install.sh` from the packages branch, then run it as root. It pins
the PEM public-key SHA256, checks that a matching feed exists, backs up an existing
Opnwall source/key, and writes:

- `/usr/local/etc/pkg/repos/opnwall-dashboard-plus.conf`
- `/usr/local/etc/pkg/keys/opnwall-dashboard-plus.pub`

Repository ID: `OpnwallDashboardPlus`; priority 30; `signature_type: pubkey`.
The original DashboardPlus source remains available for other widgets/plugins. No
existing OPNsense or third-party repository is disabled or has its trust mode changed.

After reviewing `pkg upgrade -n -r OpnwallDashboardPlus`, install/upgrade the map from this
source. OPNsense's normal firmware update check reads enabled pkg sources, so subsequent
**published package versions** will be offered. Source commits are not automatically built.
The URL includes the OPNsense series and `${ABI}`. After a major firmware-series change,
publish the matching feed and rerun the installer; this feed is not cross-version firmware.

## Maintainer publishing

Keep an offline backup of the signing private key. The local default is
`~/.local/share/opnwall/dashboard-plus/repository.key` (directory 0700, key 0600).
Never place it inside a Git checkout or a release asset. Only the public key is committed.
For Actions, the private key is stored separately in the protected `signed-release`
environment Secret; it is never a repository file or downloadable artifact.

1. Build and test the package for the target OPNsense series/ABI with `tools/build.sh`.
   Clean test bytecode from staged sources as the build script does. Bump the package
   version/revision for every release that devices should recognize as an upgrade.
2. Check out the `packages` branch separately, preserving every other package in that feed.
3. With working SSH access to a FreeBSD builder, run:

   ```sh
   SERIES=26.7 ABI=FreeBSD:15:amd64 tools/sign-feed-remote.sh /path/to/packages-checkout root@builder /path/to/os-firewall-map-VERSION.pkg
   ```

   The helper verifies that the local private key matches the committed public key,
   uploads it only to a temporary root-only builder directory, signs the catalog,
   downloads the public output, and removes the temporary private key. It never commits
   or pushes. Keep a protected offline key backup; remote signing is transient, not backup.
   For a dedicated FreeBSD signer with a protected key, `tools/publish.sh` is also available.
4. Review the feed files; commit and push the `packages` branch. Do not commit private
   keys, device configuration, login credentials, or signing scratch directories.
5. On a test firewall, require `pkg update -f -r OpnwallDashboardPlus` to succeed with the
   correct key, and fail in an isolated pkg database with a deliberately wrong key. Then
   inspect `pkg upgrade -n` and perform the intended upgrade; confirm `%R` identifies this
   source and the map's original and Mihomo collectors still function.

Public key rotation is a trust-anchor change: verify the new fingerprint separately and
install it on devices before requiring catalogs signed only by the new key. Do not work
around signature errors by disabling verification.

## Device rollback

Back up the repo config and public key before changing them. To disable only this feed,
set `enabled: no` in its `.conf`, refresh pkg catalogs, and review the upgrade plan.
Restore a previous plugin using the saved package plus any formerly unmanaged extension
files, following that backup's recovery instructions. Do not replace the global OPNsense
config or another repository's keys just to roll back the map.

## GitHub Actions

New Firewall Map releases can be built, signed and published to both channels by
[the release workflow](github-actions-release.md). Push a matching `firewall-map-VERSION`
tag from main after updating the Makefile and versioned release notes. Manual runs default
to a full signing rehearsal without public mutations. The `signed-release` environment
holds the signing Secret; the offline key backup remains necessary.
