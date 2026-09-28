<h2 align="center">
  <a href=#><img src="https://raw.githubusercontent.com/armbian/.github/master/profile/logosmall.png" alt="Armbian logo"></a>
  <br><br>
</h2>

# Armbian Config (configng)

## Purpose of This Repository

This repository holds the source for **Armbian Config**, a lightweight configuration utility that automates common system tasks on Armbian (and other systemd/APT-based Linux distributions) — from initial setup and networking, through kernel and hardware options, to sandboxed installation of desktop environments and self-hosted applications.

Armbian Config ships preinstalled on Armbian images. A full inventory of the tool's menus and modules is maintained in [DOCUMENTATION.md](DOCUMENTATION.md).

## Quick Start

Open a terminal (locally or over SSH) and run:

```bash
armbian-config
```

<a href=#><img src=.github/images/common.png></a>

## Compatibility

This tool is optimized for use with [**Armbian Linux**](https://www.armbian.com), but it should also work on any systemd-based, APT-compatible Linux distribution — including Linux Mint, Elementary OS, Kali Linux, MX Linux, Parrot OS, Proxmox, Raspberry Pi OS, and others.

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

## Repository Layout

```
bin/                 armbian-config entry point (shell)
share/               Desktop entry and icons (hicolor theme)
tools/
  config-assemble.sh Assembles modules and jobs (production or testing)
  config-markdown.py Generates Markdown docs from JSON config
  json/              Split JSON sources (help, localisation, network,
                     software, system, temp)
  modules/           Feature modules (desktops, system, ...)
  include/           Per-ID header/footer Markdown snippets and images
tests/
  *.conf             Per-feature test cases consumed by the runner
  bats/              Bats unit and integration tests + JSON fixtures
.github/             Issue/PR templates, labeler config, workflows
DOCUMENTATION.md     Generated menu/module reference
debian.conf          Debian packaging metadata
```

## Build and Test

The utility is assembled from modular sources under `tools/` before it can run from a checkout.

Assemble modules and jobs, then launch the CLI:

```bash
tools/config-assemble.sh -p   # -p: production, -t: testing
bin/armbian-config
```

Regenerate the Markdown documentation:

```bash
bin/armbian-config --doc
```

### Unit tests

Feature-level tests live in `tests/` as `*.conf` files. Each file defines a `testcase()` shell function whose success is signalled by a `0` exit status, plus `ENABLED` and optional `RELEASE` filters. See [tests/README.md](tests/README.md) for the format.

Bats unit and integration tests live under `tests/bats/`:

```bash
bats tests/bats/plan.bats tests/bats/detect.bats \
     tests/bats/detect_windows.bats tests/bats/bootconfig.bats \
     tests/bats/dualboot.bats tests/bats/transfer.bats \
     tests/bats/package.bats tests/bats/runners.bats

# Integration tests (loopback block device, dual-boot) require root:
sudo bats tests/bats/integration_loopback.bats \
          tests/bats/integration_dualboot.bats
```

## Built With

- **Bash / shell scripts** — the `armbian-config` entry point, module code under `tools/modules/`, and the assembler `tools/config-assemble.sh`.
- **Python 3** — helper tooling such as `tools/config-markdown.py`, `tools/modules/desktops/scripts/parse_desktop_yaml.py`, and the desktop-audit helpers under `tools/modules/desktops/github/` (standard library plus `pyyaml`).
- **JSON** under `tools/json/` — split sources for help, localisation, network, software and system menus that are joined into a single runtime `config.jobs.json`.
- **YAML** — GitHub Actions workflows, labeler configuration, and desktop matrix data.
- **Bats** — shell test framework used for the tests under `tests/bats/`.
- **Debian packaging** — configured via `debian.conf`; runtime dependencies include `bash`, `jq`, `whiptail`, `sudo`, `procps`, `systemd`, `lsb-release`, `iproute2`, `debconf`, `libtext-iconv-perl`, `gpg`, `xz-utils`, `pv`, `python3-yaml`, `expect-dev`, `rsync`, `parted`, `dosfstools`, `e2fsprogs`, `btrfs-progs`, `f2fs-tools`, and `ntfs-3g`.
- **Runtime UI** — `whiptail` dialogs on top of the shell modules.

## Continuous Integration

CI covers JSON validation, coding-style checks, shell linting, Bats unit and integration tests, Debian package builds, documentation regeneration, PR labelling, and periodic maintenance jobs.

For per-workflow status and history, see the Armbian CI overview for this repository:

<https://actions.armbian.com/?repo=configng>

## Contribute

We welcome contributions — new software modules, additional configuration features, tests, and documentation fixes. See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow, and the online guide:

<https://docs.armbian.com/Contribute/Armbian-config>

> 📌 Tip: Keep changes modular and easy to maintain — that speeds up review and merge.

Please also read the [Code of Conduct](CODE_OF_CONDUCT.md).

## Support

- **Community Forums** — [forum.armbian.com](https://forum.armbian.com)
- **IRC / Discord / Matrix** — [Community Chat](https://docs.armbian.com/Community_IRC/)
- **Paid consultation** — [Contact us](https://www.armbian.com/contact)

## Contributors

Thanks to everyone who has contributed to Armbian Config!

<a href="https://github.com/armbian/configng/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=armbian/configng" />
</a>
<br>
<br>

## Armbian Partners

Armbian's [partnership program](https://forum.armbian.com/subscriptions) helps to support Armbian and the Armbian community! Please take a moment to familiarize yourself with [our Partners](https://armbian.com/partners).

## License

Armbian Config is distributed under the terms of the **GNU General Public License v3.0**. See [LICENSE](LICENSE) for details.
