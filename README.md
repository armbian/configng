<h2 align="center">
  <a href=#><img src="https://raw.githubusercontent.com/armbian/.github/master/profile/logosmall.png" alt="Armbian logo"></a>
  <br><br>
</h2>

# Armbian Config (configng)

## Purpose of This Repository

This repository contains the source code for **Armbian Config**, a lightweight configuration utility for Armbian Linux that simplifies and automates common system tasks — from initial setup and networking to kernel management, desktop installation, and sandboxed software deployment.

Armbian Config is **preinstalled** on Armbian images, but can also run on any systemd + APT based Linux distribution.

## Quick Start

Open a terminal (locally or via SSH) and run:

```bash
armbian-config
```

<a href=#><img src=.github/images/common.png></a>

## Compatibility

This tool is optimized for use with [**Armbian Linux**](https://www.armbian.com), but in theory it should also work on any systemd-based, APT-compatible Linux distribution — Linux Mint, Elementary OS, Kali Linux, MX Linux, Parrot OS, Proxmox, Raspberry Pi OS, and others.

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

Armbian Config provides interactive and scriptable routines for:

- **System** — alternative kernels, headers, device-tree overlays, boot environment, install-to-internal-media, ZFS / NFS / read-only rootfs, memory tuning, SSH hardening (including 2FA/OTP), MOTD and shell switching, OS updates and distribution upgrades (stable ↔ rolling)
- **Network** — basic + advanced bridged configuration, DHCP fallback management
- **Localisation** — timezone, locales, keyboard, hostname
- **Software** — Docker / Portainer, databases (MySQL, MariaDB, PostgreSQL, Redis), DNS tooling (AdGuard Home, Pi-hole, Unbound), media servers, home automation, monitoring, backup tools, and more
- **Desktop** — install, remove, autologin and tier switching (minimal / mid / full) for Cinnamon, GNOME, MATE, i3, KDE Plasma, KDE Neon, Budgie, Deepin, Enlightenment, Bianbu, XFCE

A full list of actions is maintained in [DOCUMENTATION.md](DOCUMENTATION.md), auto-generated from the JSON job definitions in [`tools/json/`](tools/json/).

## Repository Layout

```
bin/armbian-config          Entry-point shell script
share/                      Desktop entry, icons (hicolor theme)
tools/
  config-assemble.sh        Assemble modules + jobs (production/testing)
  config-markdown.py        Generate Markdown docs from config JSON
  json/                     Config fragments: help, localisation, network,
                            software, system
  modules/                  Shell/Python modules (desktops, system, …)
  include/                  Per-ID header/footer Markdown + images
tests/
  *.conf                    Per-feature unit test cases
  bats/                     Bats test suites + lsblk JSON fixtures
.github/                    Issue/PR templates, labels, CI workflows
debian.conf                 Debian packaging metadata
```

## Built With

- **Bash** — `bin/armbian-config` and the module and tool scripts under `tools/`
- **Python 3** — documentation and audit tooling (`tools/config-markdown.py`, `tools/modules/desktops/github/*.py`, `tools/modules/desktops/scripts/parse_desktop_yaml.py`); standard library only (`json`, `sys`, `argparse`, `os`, `yaml`)
- **JSON** — configuration/job definitions under `tools/json/`
- **YAML** — desktop matrix definitions, labeler config, CI workflows
- **Bats** — shell test harness under `tests/bats/` (with `jq`, `parted`, `dosfstools`, `ntfs-3g` as test-time helpers)
- **Whiptail** — TUI frontend (runtime dependency, see `debian.conf`)
- **QML / Qt** — SDDM login theme assets under `tools/modules/desktops/greeters/sddm/`

Runtime dependencies declared for the Debian package include: `bash, jq, whiptail, sudo, procps, systemd, lsb-release, iproute2, debconf, libtext-iconv-perl, gpg, xz-utils, pv, python3-yaml, expect-dev, rsync, parted, dosfstools, e2fsprogs, btrfs-progs, f2fs-tools, ntfs-3g`.

## Building Locally

Assemble modules and jobs, then launch the result:

```bash
# For production
tools/config-assemble.sh -p

# Or for testing
tools/config-assemble.sh -t

bin/armbian-config
```

Regenerate documentation:

```bash
bin/armbian-config --doc
```

See [`tools/README.md`](tools/README.md) for details on `config-assemble.sh` and `config-markdown.py`.

## Tests

Two complementary test layers live under `tests/`:

- **Feature `.conf` cases** (`tests/*.conf`) — each file defines a `testcase()` function and metadata (`ENABLED`, `RELEASE`). A test is successful when `testcase()` returns 0. See [`tests/README.md`](tests/README.md) for the format.
- **Bats suites** (`tests/bats/`) — unit tests for pure functions plus integration tests exercising a loopback block device and Windows dual-boot detection, backed by `lsblk` JSON fixtures.

Run the Bats suite locally (requires `bats`, `jq`, `parted`, `dosfstools`, `ntfs-3g`):

```bash
bats tests/bats/plan.bats tests/bats/detect.bats tests/bats/bootconfig.bats \
     tests/bats/dualboot.bats tests/bats/transfer.bats tests/bats/package.bats \
     tests/bats/runners.bats
sudo bats tests/bats/integration_loopback.bats tests/bats/integration_dualboot.bats
```

## Continuous Integration

An overview of all CI jobs for this repository (status, history, triggers) is published at:

<https://actions.armbian.com/?repo=configng>

## Contribute

Want to extend Armbian Config with new features, software titles, or desktop options? Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) and the online guide:

<https://docs.armbian.com/Contribute/Armbian-config>

> 📌 Keep your changes modular — this makes review and merging faster.

Please also review the project [Code of Conduct](CODE_OF_CONDUCT.md).

## Support

- **Community Forums** — <https://forum.armbian.com>
- **Discord / IRC / Matrix** — <https://docs.armbian.com/Community_IRC/>
- **Paid consultation** — <https://www.armbian.com/contact>

## Contributors

Thanks to all who have contributed to Armbian Config!

<a href="https://github.com/armbian/configng/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=armbian/configng" />
</a>
<br><br>

## Armbian Partners

Armbian's [partnership program](https://forum.armbian.com/subscriptions) helps support Armbian and its community. Please take a moment to familiarize yourself with [our Partners](https://armbian.com/partners).

## License

This project is licensed under the **GNU General Public License v3.0** — see [LICENSE](LICENSE) for details.
