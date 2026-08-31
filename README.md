<h2 align="center">
  <a href=#><img src="https://raw.githubusercontent.com/armbian/.github/master/profile/logosmall.png" alt="Armbian logo"></a>
  <br><br>
</h2>

# Armbian Config

## Purpose of This Repository

This repository contains the source code of **Armbian Config** (a.k.a. `configng`), a lightweight configuration utility that simplifies and automates common system tasks — initial setup, networking, kernel/firmware management, desktop environments, and containerised or sandboxed software — on Armbian and other systemd + APT based Linux distributions.

## Quick Start

Armbian Config comes **preinstalled** on Armbian images.

To launch it from a local terminal or over SSH:

```bash
armbian-config
```

<a href=#><img src=.github/images/common.png></a>

## Compatibility

This tool is optimized for [**Armbian Linux**](https://www.armbian.com), but should also work on any systemd-based, APT-compatible Linux distribution — including Linux Mint, Elementary OS, Kali Linux, MX Linux, Parrot OS, Proxmox, Raspberry Pi OS, and others.

<details><summary>Add the Armbian key + repository and install the tool:</summary>

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
bin/                      # armbian-config entry point (Bash)
tools/
  config-assemble.sh      # Assembles modules and jobs (production/testing)
  config-markdown.py      # Generates Markdown docs from the assembled JSON
  json/                   # Job definitions (help, localisation, network,
                          #   software, system, temp)
  modules/                # Feature modules (desktops, system, …)
  include/                # Per-ID header/footer Markdown + images used by
                          #   the documentation generator
share/                    # Desktop entry and hicolor icon set
tests/
  *.conf                  # Per-function unit-test cases (ENABLED / RELEASE /
                          #   testcase())
  bats/                   # Bats tests + fixtures for the installer engine
                          #   (plan, detect, bootconfig, dualboot, transfer,
                          #   package, integration_*)
.github/                  # Issue/PR templates, labels, workflows
DOCUMENTATION.md          # Generated feature reference (produced by --doc)
CONTRIBUTING.md           # Contribution workflow
CODE_OF_CONDUCT.md
LICENSE                   # GNU GPL v3
debian.conf               # Debian packaging metadata
```

## Building and Assembling

The runtime is composed by `tools/config-assemble.sh`, which stitches JSON parts under `tools/json/` and Bash modules under `tools/modules/` into the file consumed by `bin/armbian-config`.

```bash
tools/config-assemble.sh -h    # show options
tools/config-assemble.sh -p    # assemble for production
tools/config-assemble.sh -t    # assemble for testing
bin/armbian-config
```

Generate the Markdown documentation (writes into `docs/`) after assembling:

```bash
bin/armbian-config --doc
# or, directly:
python3 tools/config-markdown.py -u   # user documentation
python3 tools/config-markdown.py -t   # technical documentation
```

Header/footer/image assets keyed by feature ID live under `tools/include/markdown/` and `tools/include/images/` and are embedded automatically.

## Testing

Two complementary test suites are shipped:

- **Function unit tests** under `tests/*.conf`. Each file is named after a function ID and defines `ENABLED`, an optional `RELEASE` filter (e.g. `bookworm:jammy:noble`), and a `testcase()` shell function that returns `0` on success. Example:

  ```sh
  ENABLED=true
  RELEASE="bookworm:noble"

  testcase() {
      ./bin/armbian-config --api module_cockpit install
      [ -f /usr/bin/cockpit-bridge ]
  }
  ```

  See [`tests/README.md`](tests/README.md) for the multi-condition pattern using a `( set -e … )` subshell.

- **Bats tests** under `tests/bats/` covering the installer engine (plan, block-device detection, Windows detection, boot config, dual-boot, transfer, package handling) plus root-required loopback and dual-boot integration tests. Fixtures such as `lsblk_*.json` live in `tests/bats/fixtures/`.

  ```bash
  sudo apt-get install -y bats jq parted dosfstools ntfs-3g
  bats tests/bats/plan.bats tests/bats/detect.bats tests/bats/detect_windows.bats \
       tests/bats/bootconfig.bats tests/bats/dualboot.bats tests/bats/transfer.bats \
       tests/bats/package.bats
  sudo bats tests/bats/integration_loopback.bats tests/bats/integration_dualboot.bats
  ```

## Built With

- **Bash** — the CLI (`bin/armbian-config`), the module library under `tools/modules/`, the assembler `tools/config-assemble.sh`, and the Bats-based installer tests.
- **Python 3** — the documentation generator `tools/config-markdown.py` and the desktop-matrix audit helpers under `tools/modules/desktops/github/` and `tools/modules/desktops/scripts/`. The docs generator uses only Python's standard library (`json`, `sys`, `argparse`, `os`); the desktop audit tooling additionally uses `pyyaml`.
- **JSON / YAML** — job definitions in `tools/json/` and desktop matrices/branding under `tools/modules/desktops/`.
- **QML** — the shipped `plasma-chili` SDDM greeter theme.
- **whiptail**, **jq**, **systemd**, **APT**, and related tooling at runtime, as declared in the Debian packaging depends list.

## Continuous Integration

Automated jobs cover JSON validation, coding-style / lint / Bats runs, Debian package builds, doc regeneration, PR labelling and review handling, stale-issue management, and the desktop matrix audit.

A live overview of workflows and their current status for this repository is available here:

**https://actions.armbian.com/?repo=configng**

## Contributing

We welcome contributions — new software modules, desktop matrix improvements, bug fixes, documentation, and test cases. Please read:

- [CONTRIBUTING.md](CONTRIBUTING.md) — how to fork, branch, test, and submit PRs
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- <https://docs.armbian.com/Contribute/Armbian-config>

Labels are defined in [`.github/labels.yml`](.github/labels.yml) and are kept in sync automatically.

> 📌 Tip: Keep changes modular — smaller, focused PRs are reviewed and merged faster.

## Support

- **Community forums** — <https://forum.armbian.com>
- **Real-time chat (IRC / Matrix / Discord)** — <https://docs.armbian.com/Community_IRC/>
- **Paid consultation** — <https://www.armbian.com/contact>

## License

Distributed under the **GNU General Public License v3.0**. See [LICENSE](LICENSE) for the full text.

## Contributors

Thanks to everyone who has contributed to Armbian Config!

<a href="https://github.com/armbian/configng/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=armbian/configng" />
</a>

## Armbian Partners

Armbian's [partnership program](https://forum.armbian.com/subscriptions) helps support the project and community. Learn more about [our Partners](https://armbian.com/partners).
