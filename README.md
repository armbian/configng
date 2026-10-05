<h2 align="center">
  <a href=#><img src="https://raw.githubusercontent.com/armbian/.github/master/profile/logosmall.png" alt="Armbian logo"></a>
  <br><br>
</h2>

# Armbian Config (configng)

## Purpose of This Repository

This repository contains the source code of **Armbian Config**, a lightweight, modular configuration utility for Armbian (and other systemd + APT–based Linux distributions). It bundles interactive and scriptable routines for initial setup, networking, kernel and bootloader management, desktop installation and branding, and sandboxed software deployment on single board computers.

## Quick Start

Armbian Config comes **preinstalled** with Armbian images. To launch it:

```bash
armbian-config
```

<a href=#><img src=.github/images/common.png></a>

The utility can also be driven non-interactively through its API, e.g.:

```bash
armbian-config --api module_cockpit install
```

## Compatibility

This tool is optimized for use with [**Armbian Linux**](https://www.armbian.com), but in principle it also works on any systemd-based, APT-compatible Linux distribution — including Linux Mint, Elementary OS, Kali Linux, MX Linux, Parrot OS, Proxmox, Raspberry Pi OS, and others.

<details><summary>Add Armbian key + repository and install the tool:</summary>

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

## What's Inside

Armbian Config exposes groups of features (see [`DOCUMENTATION.md`](DOCUMENTATION.md) for the full generated reference):

- **System** — alternative kernels, headers, device-tree overlays, boot environment, desktop environments (XFCE, GNOME, KDE Plasma, KDE Neon, MATE, Cinnamon, Budgie, Deepin, Enlightenment, i3, Bianbu), ZFS/NFS, read-only rootfs, memory and tuning profiles, SSH hardening (incl. 2FA), MOTD and shell switching, OS updates and distribution upgrades.
- **Network** — basic and advanced bridged configuration, fallback DHCP management, status inspection.
- **Localisation** — timezone, locales, keyboard layout, hostname.
- **Software** — Docker/Portainer, databases (MariaDB, MySQL, PostgreSQL, Redis, phpMyAdmin), ad blockers (AdGuardHome, Pi-hole, Unbound), media/*arr stack, home automation, backup tools, and Armbian infrastructure services (CDN router, GitHub runners, rsyncd).

## Repository Layout

```text
bin/armbian-config           Entry-point script (installed as the armbian-config command)
debian.conf                  Debian packaging metadata used by the build workflow
DOCUMENTATION.md             Generated feature reference
share/                       Desktop entry and hicolor icon set (16–256 px, scalable SVGs)
tests/                       Per-feature unit test .conf files + Bats test suites and fixtures
tools/
  config-assemble.sh         Assembles modules and jobs for production (-p) or testing (-t)
  config-markdown.py         Generates technical / user Markdown docs from the merged JSON
  json/                      Source JSON parts (help, localisation, network, software, system, temp)
  modules/                   Shell modules and desktop assets grouped by feature
  include/
    markdown/                Per-ID header/footer snippets embedded into generated docs
    images/                  Per-ID screenshots and icons used by the docs generator
.github/                     Issue/PR templates, labeler config, and CI workflows
```

## Built With

- **Bash / shell** — the `armbian-config` entry point (`bin/armbian-config`), the module library under `tools/modules/`, the assembler `tools/config-assemble.sh`, and the Bats test files in `tests/bats/`.
- **Python 3** — the docs generator `tools/config-markdown.py` (standard library only: `json`, `sys`, `argparse`, `os`), the desktop YAML parser `tools/modules/desktops/scripts/parse_desktop_yaml.py`, and the desktop matrix audit scripts in `tools/modules/desktops/github/` (`pyyaml` for the audit).
- **JSON** — feature definitions in `tools/json/*.json` (merged at assembly time into a runtime config).
- **YAML** — GitHub Actions workflows, label/dependabot/issue-template configuration, and desktop matrix definitions.
- **QML / Qt** — the bundled SDDM `plasma-chili` greeter theme under `tools/modules/desktops/greeters/sddm/themes/`.
- **Runtime dependencies** (from `debian.conf`): `bash`, `jq`, `whiptail`, `sudo`, `procps`, `systemd`, `lsb-release`, `iproute2`, `debconf`, `libtext-iconv-perl`, `gpg`, `xz-utils`, `pv`, `python3-yaml`, `expect-dev`, `rsync`, `parted`, `dosfstools`, `e2fsprogs`, `btrfs-progs`, `f2fs-tools`, `ntfs-3g`.

## Development

Clone your fork, assemble the modules, and run the tool from the working tree:

```bash
tools/config-assemble.sh -p    # production assembly; use -t for testing
bin/armbian-config
```

Generate the Markdown documentation:

```bash
bin/armbian-config --doc
```

See [`tools/README.md`](tools/README.md) for details on `config-assemble.sh` and `config-markdown.py`, and [`tools/include/README.md`](tools/include/README.md) for how per-ID headers, footers, and images are embedded into the generated docs.

### Tests

Two test harnesses live side-by-side under `tests/`:

- **Feature `.conf` tests** — one file per feature, with an `ENABLED` flag, an optional `RELEASE` whitelist, and a `testcase()` function. See [`tests/README.md`](tests/README.md) for the contract and examples.
- **Bats tests** — pure-function unit tests and loopback/dual-boot integration tests under `tests/bats/` with JSON fixtures in `tests/bats/fixtures/`.

Run the Bats suite locally (requires `bats`, `jq`, `parted`, `dosfstools`, `ntfs-3g`):

```bash
bats tests/bats/plan.bats tests/bats/detect.bats tests/bats/bootconfig.bats \
     tests/bats/dualboot.bats tests/bats/transfer.bats tests/bats/package.bats \
     tests/bats/runners.bats
sudo bats tests/bats/integration_loopback.bats tests/bats/integration_dualboot.bats
```

## Continuous Integration

CI (packaging, documentation builds, JSON validation, lint and coding-style checks, Bats, desktop matrix auditing, labelers and housekeeping) is defined under `.github/workflows/`. A live overview of all CI jobs for this repository is available here:

<https://actions.armbian.com/?repo=configng>

## Contribute

Want to expand **Armbian Config** with new features or tools? Whether you're adding a new software title, enhancing an existing configuration module, or introducing entirely new functionality, we welcome your ideas and code.

<https://docs.armbian.com/Contribute/Armbian-config>

See also [`CONTRIBUTING.md`](CONTRIBUTING.md) for environment setup, branching, labelling conventions, and PR expectations, and [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

> 📌 Tip: Keep your changes modular and easy to maintain — this helps us review and merge your contribution faster.

## Support

Armbian offers multiple support channels, depending on your needs:

- **Community Forums** — [forum.armbian.com](https://forum.armbian.com)
- **Discord / IRC / Matrix Chat** — [Community Chat](https://docs.armbian.com/Community_IRC/)
- **Paid Consultation** — [Contact us](https://www.armbian.com/contact) for commercial support and consulting options.

## License

Armbian Config is distributed under the terms of the **GNU General Public License v3.0**. See [`LICENSE`](LICENSE) for the full text.

## Contributors

Thanks to all who have contributed to Armbian Config!

<a href="https://github.com/armbian/configng/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=armbian/configng" />
</a>
<br>
<br>

## Armbian Partners

Armbian's [partnership program](https://forum.armbian.com/subscriptions) helps to support Armbian and the Armbian community! Please take a moment to familiarize yourself with [our Partners](https://armbian.com/partners).
