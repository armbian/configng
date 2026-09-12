<h2 align="center">
  <a href=#><img src="https://raw.githubusercontent.com/armbian/.github/master/profile/logosmall.png" alt="Armbian logo"></a>
  <br><br>
</h2>

# Armbian Config

## Purpose of This Repository

This repository contains the source code for **Armbian Config** (`armbian-config`), a lightweight configuration utility that simplifies and automates common system tasks on Armbian and other systemd/APT-based Linux distributions — from network and kernel management to sandboxed application installs and desktop environment provisioning.

## Overview

Armbian Config provides interactive and scriptable routines for:

- Initial system setup and personalization
- Networking configuration, including Wi-Fi, VPN, bridged interfaces and static IP
- Sandboxed software installation and system updates
- Kernel selection, switching, headers, device tree overlays and boot environment editing
- Enabling and managing hardware-specific features
- Desktop environment installation, tiered management (minimal / mid / full) and Armbian branding for XFCE, GNOME, KDE Plasma / Neon, MATE, Cinnamon, Budgie, Deepin, Enlightenment, i3, xmonad, LXQt and Bianbu
- Filesystem support (ZFS, NFS, read-only rootfs) and installation to internal media
- Optional dual-boot alongside Windows and disk transfer tooling

A full, generated inventory of menus and actions lives in [`DOCUMENTATION.md`](DOCUMENTATION.md).

## Quick Start

Armbian Config comes **preinstalled** on Armbian images. To launch it:

```bash
sudo armbian-config
```

<a href=#><img src=".github/images/common.png"></a>

## Compatibility

Optimized for [**Armbian Linux**](https://www.armbian.com), but designed to also work on any systemd-based, APT-compatible Linux distribution — Debian, Ubuntu, Linux Mint, Elementary OS, Kali Linux, MX Linux, Parrot OS, Proxmox, Raspberry Pi OS and similar.

<details><summary>Add the Armbian key + repository and install the tool on a non-Armbian system:</summary>

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
bin/                     Launcher script (armbian-config)
share/                   Desktop entry and icon set (hicolor theme)
tools/
  config-assemble.sh     Assembles modules and jobs (production / testing)
  config-markdown.py     Generates Markdown docs from the assembled JSON
  json/                  Split JSON config sources (help, localisation,
                         network, software, system, temp)
  modules/               Shell modules — desktops, system, and more
  include/               Per-ID Markdown headers/footers and images
                         embedded into the generated documentation
tests/
  *.conf                 Per-module functional test cases
  bats/                  Bats unit and integration tests + fixtures
.github/                 Issue/PR templates, labels, dependabot, CI workflows
DOCUMENTATION.md         Auto-generated menu/action reference
CONTRIBUTING.md          Contributor guide
CODE_OF_CONDUCT.md       Community expectations
debian.conf              Debian packaging metadata
```

## Built With

- **Bash** — `bin/armbian-config`, module scripts under `tools/modules/`, tooling entry points
- **Python 3** — documentation generator (`tools/config-markdown.py`), desktop matrix audit (`tools/modules/desktops/github/*.py`) and helper scripts; only the standard library is required (`json`, `sys`, `argparse`, `os`)
- **JSON** — configuration sources under `tools/json/` (help, localisation, network, software, system) plus browser policy files under `tools/modules/desktops/branding/browsers/`
- **YAML** — GitHub Actions workflows, issue templates, labeler config, and desktop matrix definitions
- **Markdown** — user-facing docs and per-ID header/footer fragments in `tools/include/markdown/`
- **QML** — SDDM greeter theme (`plasma-chili`) shipped with the desktop branding
- **Bats** — unit and integration test framework (see `tests/bats/`); the test job additionally installs `jq`, `parted`, `dosfstools` and `ntfs-3g`
- Runtime user tooling includes `whiptail`, `jq`, `sudo`, `systemd`, `gpg`, `rsync`, `python3-yaml`, `parted`, `dosfstools`, `e2fsprogs`, `btrfs-progs`, `f2fs-tools` and `ntfs-3g` (see `.github/workflows/maintenance-build-debian.yml` for the full Debian `depends` list).

## Building From Source

Assemble the modules and job definitions, then run the launcher:

```bash
# Production build
tools/config-assemble.sh -p

# Testing build
tools/config-assemble.sh -t

# Run
bin/armbian-config
```

Show tool help:

```bash
./tools/config-assemble.sh -h
python3 tools/config-markdown.py -h
```

## Testing

Two test surfaces live alongside the code:

- **`tests/*.conf`** — per-module functional cases. Each file defines an `ENABLED` flag, an optional `RELEASE` filter (e.g. `bookworm:noble`), and a `testcase()` shell function whose zero return means success. See [`tests/README.md`](tests/README.md) for the conventions.
- **`tests/bats/`** — Bats unit tests (pure functions) and integration tests (loopback block device, Windows dual-boot). The integration suites require root.

```bash
# Unit tests
bats tests/bats/plan.bats tests/bats/detect.bats tests/bats/detect_windows.bats \
     tests/bats/bootconfig.bats tests/bats/dualboot.bats tests/bats/transfer.bats \
     tests/bats/package.bats

# Integration tests (need root)
sudo bats tests/bats/integration_loopback.bats tests/bats/integration_dualboot.bats
```

## Documentation

- [`DOCUMENTATION.md`](DOCUMENTATION.md) — full, auto-generated menu and action reference (regenerated by `bin/armbian-config --doc` after a `config-assemble.sh -p` build).
- [`tools/README.md`](tools/README.md) — details on `config-assemble.sh` and `config-markdown.py`.
- [`tools/include/README.md`](tools/include/README.md) — how per-ID Markdown headers/footers and images are embedded.
- Online: <https://docs.armbian.com/Contribute/Armbian-config>

## Continuous Integration

CI covers JSON validation, Bats and functional tests, shellcheck / coding-style linting, PR labeling, Debian package build and periodic desktop matrix audits. For an overview of every workflow and its recent runs, see:

<https://actions.armbian.com/?repo=configng>

## Contributing

Contributions of any size are welcome — typos, tests, new software modules, bug fixes, larger features. Start with [`CONTRIBUTING.md`](CONTRIBUTING.md), and please review our [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

> 📌 Tip: keep changes modular and focused — smaller, self-contained PRs are much easier to review and merge.

## Support

- **Community forums** — <https://forum.armbian.com>
- **Discord / IRC / Matrix chat** — <https://docs.armbian.com/Community_IRC/>
- **Paid consultation** — <https://www.armbian.com/contact>

## Contributors

Thanks to everyone who has contributed to Armbian Config!

<a href="https://github.com/armbian/configng/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=armbian/configng" />
</a>

## Armbian Partners

Armbian's [partnership program](https://forum.armbian.com/subscriptions) helps sustain Armbian and its community. Please take a moment to meet [our partners](https://armbian.com/partners).

## License

Distributed under the **GNU General Public License v3.0**. See [`LICENSE`](LICENSE) for details.
