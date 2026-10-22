<h2 align="center">
  <a href=#><img src="https://raw.githubusercontent.com/armbian/.github/master/profile/logosmall.png" alt="Armbian logo"></a>
  <br><br>
</h2>

# Armbian Config (configng)

## Purpose of This Repository

This repository holds the source code for **Armbian Config** (`armbian-config`), a lightweight interactive and scriptable configuration utility for Armbian and other systemd-based, APT-compatible Linux distributions. It automates common system setup, networking, kernel/firmware, desktop environment, and sandboxed application-install tasks — especially on single board computers (SBCs).

## Quick Start

Armbian Config ships preinstalled with Armbian images. To launch the utility:

```bash
sudo armbian-config
```

<a href=#><img src=.github/images/common.png></a>

## Compatibility

This tool is optimized for use with [**Armbian Linux**](https://www.armbian.com), but should also work on any systemd-based, APT-compatible Linux distribution — including Linux Mint, Elementary OS, Kali Linux, MX Linux, Parrot OS, Proxmox, Raspberry Pi OS, and others.

<details><summary>Add Armbian key + repository and install the tool on a non-Armbian host:</summary>

```bash
wget -qO - https://apt.armbian.com/armbian.key | gpg --dearmor | \
sudo tee /usr/share/keyrings/armbian.gpg > /dev/null
cat << EOF | sudo tee /etc/apt/sources.list.d/armbian-config.sources > /dev/null
Types: deb
URIs: https://github.armbian.com/configng
Suites: stable
Components: main
Signed-By: /usr/share/keyrings/armbian.gpg
EOF
sudo apt update
sudo apt -y install armbian-config
armbian-config
```

</details>

## Repository Layout

```
bin/armbian-config         Entry-point script invoked by users
tools/config-assemble.sh   Assembles modules and jobs (production / testing)
tools/config-markdown.py   Generates Markdown documentation from the JSON config
tools/json/                JSON config fragments (help, localisation, network,
                           software, system, temp) assembled into the runtime
                           config.jobs.json
tools/modules/             Shell/Python modules (desktops, system, ...)
tools/include/             Markdown headers/footers and images embedded into
                           generated documentation
tests/                     Unit test .conf files (per feature/application) and
                           Bats test suites under tests/bats/
share/                     Desktop entry (configng.desktop) and hicolor icons
.github/                   Issue/PR templates, labeler config, workflows
DOCUMENTATION.md           Auto-generated feature overview
debian.conf                Debian packaging configuration
```

## What's Inside

Armbian Config exposes interactive and `--api`-callable routines across several areas, including:

- **System** — alternative kernels, headers, device-tree overlays, boot environment, memory/tuning profiles, install-to-internal-media, ZFS/NFS, read-only rootfs, SSH daemon hardening (2FA/OTP), MOTD/shell switching, OS updates and rolling/stable channel switching.
- **Desktop environments** — install, uninstall, tier-switch (minimal/mid/full), autologin, and branding for XFCE, GNOME, KDE Plasma, KDE Neon, MATE, Cinnamon, Budgie, Deepin, Enlightenment, i3, XMonad, Bianbu.
- **Network** — basic/advanced setup, bridged configuration, view/revert config.
- **Localisation** — timezone, locales, keyboard layout, hostname.
- **Software** — containerisation (Docker, Portainer), databases (MariaDB/MySQL, PostgreSQL, Redis, phpMyAdmin), ad-blocking DNS (AdGuardHome, Pi-hole, Unbound), media/download stacks (Jellyfin, Emby, Sonarr/Radarr/Lidarr/Prowlarr/Bazarr, qBittorrent, Transmission, Deluge, SABnzbd, Medusa), home automation and dashboards (Home Assistant, Domoticz, openHAB, Homepage, Netdata, Grafana, Prometheus, Uptime Kuma), file sharing (Samba, Nextcloud, ownCloud, Syncthing, Filebrowser), and Armbian-internal services (CDN router, GitHub Actions runners, rsyncd server), among others.

A full, auto-generated feature index lives in [DOCUMENTATION.md](DOCUMENTATION.md).

## Building From Source

Armbian Config is primarily written in **Bash** (`bin/armbian-config` and the `tools/modules/**/*.sh` modules), with **Python 3** helpers (`tools/config-markdown.py`, `tools/modules/desktops/github/*.py`, `tools/modules/desktops/scripts/parse_desktop_yaml.py`), YAML module/matrix definitions, and JSON configuration fragments. The Debian package is produced from `debian.conf` by the shared Armbian packaging workflow.

Assemble modules and jobs locally:

```bash
tools/config-assemble.sh -p    # production
tools/config-assemble.sh -t    # testing
bin/armbian-config
```

Regenerate documentation (writes into `docs/`, consumes the assembled `config.jobs.json`):

```bash
bin/armbian-config --doc
# or directly:
python3 tools/config-markdown.py -u    # user documentation
python3 tools/config-markdown.py -t    # technical documentation
```

See [`tools/README.md`](tools/README.md) and [`tools/include/README.md`](tools/include/README.md) for details on the assembler and the per-ID header/footer/image embedding convention.

## Testing

Two test suites are maintained in this repository:

- **Feature test cases** under [`tests/`](tests/) — one `.conf` per feature/application defining `ENABLED`, optional `RELEASE` filter, and a `testcase()` shell function. See [`tests/README.md`](tests/README.md) for the format and examples.
- **Bats unit and integration tests** under `tests/bats/` — covering the installer engine (planning, detection, boot/dual-boot config, partitioner, transfer, package handling, runners, networking). Unit tests run unprivileged; `integration_loopback.bats` and `integration_dualboot.bats` need root and run against loopback block devices.

Run the Bats suite locally (requires `bats`, `jq`, `parted`, `dosfstools`, `ntfs-3g`):

```bash
bats tests/bats/plan.bats tests/bats/detect.bats tests/bats/detect_windows.bats \
     tests/bats/bootconfig.bats tests/bats/dualboot.bats tests/bats/transfer.bats \
     tests/bats/package.bats tests/bats/runners.bats tests/bats/partitioner.bats

sudo bats tests/bats/integration_loopback.bats tests/bats/integration_dualboot.bats
```

## Continuous Integration

A full overview of CI workflows and their current status for this repository is available at:

<https://actions.armbian.com/?repo=configng>

## Contributing

Pull requests of all sizes are welcome — typo fixes, new application modules, additional test cases, desktop improvements, documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for environment setup, branch/label conventions, and commit-message expectations, and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community guidelines.

Project-wide contributor documentation: <https://docs.armbian.com/Contribute/Armbian-config>

> 📌 Tip: Keep changes modular — this makes review and merge easier.

## Support

- **Community Forums** — [forum.armbian.com](https://forum.armbian.com)
- **Discord / IRC / Matrix Chat** — [Community Chat](https://docs.armbian.com/Community_IRC/)
- **Paid Consultation** — [Contact us](https://www.armbian.com/contact)

## License

Armbian Config is released under the GNU General Public License v3.0 — see [LICENSE](LICENSE).

## Contributors

Thanks to everyone who has contributed to Armbian Config!

<a href="https://github.com/armbian/configng/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=armbian/configng" />
</a>

## Armbian Partners

Armbian's [partnership program](https://forum.armbian.com/subscriptions) helps support Armbian and the Armbian community. Please take a moment to familiarize yourself with [our Partners](https://armbian.com/partners).
