<h2 align="center">
  <a href=#><img src="https://raw.githubusercontent.com/armbian/.github/master/profile/logosmall.png" alt="Armbian logo"></a>
  <br><br>
</h2>

# Armbian Config (configng)

## Purpose of This Repository

This repository contains the source code for **Armbian Config**, a lightweight configuration utility for Armbian Linux (and other systemd-based, APT-compatible distributions) that automates common system tasks — initial setup, networking, kernel and firmware management, desktop environment installation, and sandboxed software provisioning — through both interactive menus (whiptail) and a scriptable CLI API.

## Quick Start

Armbian Config comes **preinstalled** with Armbian images.

To launch the utility, open a terminal (locally or via SSH) and run:

```bash
armbian-config
```

<a href=#><img src=.github/images/common.png></a>

## Compatibility

This tool is optimized for use with [**Armbian Linux**](https://www.armbian.com), but should also work on any systemd-based, APT-compatible Linux distribution — including Linux Mint, Elementary OS, Kali Linux, MX Linux, Parrot OS, Proxmox, Raspberry Pi OS, and others.

<details><summary>Add Armbian key + repository and install the tool</summary>

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

## Features

Armbian Config exposes routines organized into several high-level areas (see [DOCUMENTATION.md](DOCUMENTATION.md) for the full generated menu tree):

- **System** — alternative kernels, headers, device tree overlays, boot environment; install / remove / switch desktop environments (Cinnamon, GNOME, MATE, i3, KDE Plasma, KDE Neon, Budgie, Deepin, Enlightenment, Bianbu, XFCE) in minimal / mid / full tiers; install to internal media, ZFS, NFS, read-only rootfs; SSH daemon options and 2FA; shell selection and MOTD; OS updates and distribution upgrades.
- **Network** — basic and advanced (bridged) network configuration.
- **Localisation** — timezone, locales, keyboard layout, hostname.
- **Software** — Armbian infrastructure services, backup solutions (Duplicati), containerization (Docker, Portainer), DNS ad blockers (AdGuardHome, Pi-hole, Unbound), SQL databases (MySQL, MariaDB, PostgreSQL, Redis, phpMyAdmin), development tools, and a large catalog of self-hosted applications (Home Assistant, Jellyfin, Nextcloud, Grafana, Prometheus, Netdata, Immich, Syncthing, Transmission, and many more).

## Repository Layout

```text
bin/armbian-config          Entry point script
debian.conf                 Debian packaging metadata
DOCUMENTATION.md            Auto-generated feature documentation
share/                      Desktop entry and hicolor icons
tools/                      Sources for the assembled utility
  config-assemble.sh        Assembles modules and jobs (production or testing)
  config-markdown.py        Generates Markdown docs from the JSON config
  json/                     Menu / job definitions (help, localisation,
                            network, software, system, temp)
  modules/                  Feature modules (bash + supporting assets)
    desktops/               Desktop environment installers, branding,
                            greeters, per-DE postinst scripts, skel
  include/                  Header/footer Markdown + images for docs
tests/                      Unit test conf files + Bats test suites
  bats/                     Bats tests and lsblk JSON fixtures
```

## Building & Development

The Debian package is produced from `tools/config-assemble.sh`, which stitches modules and JSON job definitions into the runtime layout consumed by `bin/armbian-config`.

Assemble for production or for testing:

```bash
tools/config-assemble.sh -p   # production
tools/config-assemble.sh -t   # testing
bin/armbian-config
```

Regenerate the Markdown documentation from the assembled JSON:

```bash
python3 tools/config-markdown.py -u   # user-facing docs
python3 tools/config-markdown.py -t   # technical docs
```

See [tools/README.md](tools/README.md) for details.

### Built With

- **Bash** — the core utility (`bin/armbian-config`), all modules under `tools/modules/`, and `tools/config-assemble.sh`.
- **Python 3** — `tools/config-markdown.py`, `tools/modules/desktops/scripts/parse_desktop_yaml.py`, and the desktop matrix audit helpers (`audit.py`, `audit_apply.py`, `audit_prompt.py`); uses only the standard library.
- **JSON** — menu, job, and configuration definitions under `tools/json/` and browser policy files.
- **YAML** — GitHub Actions workflows, issue templates, labeler configuration, and desktop matrix definitions.
- **QML** — the bundled `plasma-chili` SDDM greeter theme.
- **Bats** — unit and integration test framework (`tests/bats/`).
- Runtime dependencies (from `.github/workflows/maintenance-build-debian.yml`): `bash, jq, whiptail, sudo, procps, systemd, lsb-release, iproute2, debconf, libtext-iconv-perl, gpg, xz-utils, pv, python3-yaml, expect-dev, rsync, parted, dosfstools, e2fsprogs, btrfs-progs, f2fs-tools, ntfs-3g`.

## Testing

Two complementary test suites live in `tests/`:

- **Bats** tests under `tests/bats/` cover the installer engine's pure functions (`plan.bats`, `detect.bats`, `detect_windows.bats`, `bootconfig.bats`, `dualboot.bats`, `transfer.bats`, `package.bats`, `runners.bats`) plus loopback and Windows dual-boot integration tests (which require root). Fixtures such as `lsblk_*.json` under `tests/bats/fixtures/` back the detection tests.
- **Functional test cases** as `tests/<ID>.conf` files, each defining a `testcase()` function that must return 0 for success. Each file declares `ENABLED=true|false` and an optional `RELEASE="bookworm:jammy:noble"` list. See [tests/README.md](tests/README.md) for the format.

Run Bats tests locally:

```bash
bats tests/bats/plan.bats tests/bats/detect.bats tests/bats/bootconfig.bats \
     tests/bats/dualboot.bats tests/bats/transfer.bats tests/bats/package.bats \
     tests/bats/runners.bats
sudo bats tests/bats/integration_loopback.bats tests/bats/integration_dualboot.bats
```

## Continuous Integration

For the current status of all automated workflows in this repository (build, lint, docs, JSON validation, Bats, coding style, PR labeling, stale management, etc.), see the Armbian CI overview:

<https://actions.armbian.com/?repo=configng>

## Contributing

Want to add new software titles, extend a configuration module, or introduce new functionality? Contributions are very welcome.

- Read [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow (fork, branch, submit PR).
- Follow the [Code of Conduct](CODE_OF_CONDUCT.md).
- Development guide: <https://docs.armbian.com/Contribute/Armbian-config>

> 📌 Keep changes modular and easy to maintain — that helps reviewers merge your contribution faster.

## Support

- **Community forums** — [forum.armbian.com](https://forum.armbian.com)
- **Chat (Discord / IRC / Matrix)** — [Community Chat](https://docs.armbian.com/Community_IRC/)
- **Paid consultation** — [Contact us](https://www.armbian.com/contact)

## License

Armbian Config is released under the GNU General Public License v3.0. See [LICENSE](LICENSE) for the full text.

## Contributors

Thanks to all who have contributed to Armbian Config!

<a href="https://github.com/armbian/configng/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=armbian/configng" />
</a>
<br>
<br>

## Armbian Partners

Armbian's [partnership program](https://forum.armbian.com/subscriptions) helps support Armbian and its community. Please take a moment to familiarize yourself with [our Partners](https://armbian.com/partners).
