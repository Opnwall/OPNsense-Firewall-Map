# OPNsense-Firewall-Map signed packages

Feed: `repo/<OPNsense series>/<ABI>/`. Currently OPNsense 26.7, FreeBSD:15:amd64.
Repository ID: `OpnwallDashboardPlus`, priority 30, RSA public-key catalog verification.
This repository publishes only os-firewall-map. The legacy repository ID and public-key filename remain unchanged for compatibility with installed devices. Other repositories are not modified.

Public key: `keys/opnwall-dashboard-plus.pub`.
SHA256 of this PEM file: `5a016623073d35afbaac96c9d97081e3f9bc7d0ff2a4b2c20aed7390936a2a31`.
Only the public key belongs in this branch; the private key is never committed.

Download and review install.sh, then run it as root on the supported OPNsense release.
The installer verifies the pinned key, configures this source and verifies its catalog;
it does not install or upgrade plugins. Review the upgrade plan before applying it.

```sh
fetch -o /tmp/opnwall-dashboard-install.sh https://raw.githubusercontent.com/Opnwall/OPNsense-Firewall-Map/packages/install.sh
sh /tmp/opnwall-dashboard-install.sh
pkg upgrade -n -r OpnwallDashboardPlus
```

OPNsense System → Firmware → Status / Updates uses enabled pkg repositories. New packages
appear only after the maintainer builds, signs and publishes them; new Git commits alone
are not automatic package releases. Only packages available for the configured series/ABI
are offered. A major OPNsense series change needs a matching feed and installer rerun.

Publishing and key management: see docs/signed-repository.md on the main branch.
