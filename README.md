<h2 align="center">
  <a href=#><img src="https://raw.githubusercontent.com/armbian/.github/master/profile/logosmall.png" alt="Armbian logo"></a>
  <br><br>
</h2>

# Armbian Config

## Purpose of This Repository

This repository contains the source code for **Armbian Config**, a lightweight configuration utility that automates common system tasks on Armbian — initial setup, networking, software installation, kernel/firmware management, hardware tweaks, and desktop environment management.

Armbian Config ships preinstalled with Armbian images and is especially useful for single board computers (SBCs), helping users prepare a ready-to-use system without manual intervention.

## Quick Start

Launch the utility from a local terminal or over SSH:

```bash
armbian-config
```

<a href=#><img src=.github/images/common.png></a>

## Compatibility

Armbian Config is optimized for use with [**Armbian Linux**](https://www.armbian.com), but should also work on any systemd-based, APT-compatible Linux distribution — including Linux Mint, Elementary OS, Kali Linux, MX Linux, Parrot OS, Proxmox, Raspberry Pi OS, and others.

<details><summary>Add the Armbian key and repository, then install the tool:</summary>

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

## Documentation

- Main configuration documentation: <https://docs.armbian.com/config/>
- Software section: <https://docs.armbian.com/software/>
- Generated reference in this repository: [`DOCUMENTATION.md`](DOCUMENTATION.md)

## Repository Layout

```
bin/armbian-config          Entry point script
tools/config-assemble.sh    Assembles modules and jobs (production / testing)
tools/config-markdown.py    Generates Markdown docs from the merged JSON
tools/json/                 Per-section JSON (help, localisation, network, software, system, temp)
tools/modules/              Shell modules (desktops, system, etc.) and desktop assets
tools/include/              Per-ID header/footer Markdown snippets and images
share/                      .desktop entry and application icons
tests/                      Per-feature unit test .conf files and bats test suites
debian.conf                 Debian packaging metadata
```

Not every subdirectory is listed above — browse the tree for the full picture.

## Building and Testing Locally

Prepare a working checkout, assemble the runtime, and run the tool:

```bash
tools/config-assemble.sh -p   # -p production, -t testing
bin/armbian-config
```

Generate the Markdown documentation (requires an assembled JSON):

```bash
python3 tools/config-markdown.py -u   # user docs
python3 tools/config-markdown.py -t   # technical docs
```

Unit tests live in `tests/`. Each `<ID>.conf` file defines a `testcase()` shell function that returns 0 on success; see [`tests/README.md`](tests/README.md) for the format. Bats-based tests for the installer engine live under `tests/bats/`.

## Built With

- **Bash** — the `armbian-config` entry point, assembly tooling (`tools/config-assemble.sh`), and the modules under `tools/modules/`
- **Python 3** — documentation generator (`tools/config-markdown.py`) and the desktop matrix audit tooling under `tools/modules/desktops/github/`
- **JSON** — configuration data under `tools/json/`
- **YAML** — GitHub Actions workflows, labeler/labels config, and desktop matrix definitions
- **Bats** + `jq` — installer-engine unit and integration tests
- **whiptail** — interactive text UI (dialogs), per the Debian packaging dependencies
- **QML / Qt** — SDDM "plasma-chili" greeter theme bundled under `tools/modules/desktops/greeters/sddm/`

Debian packaging (see `debian.conf`) declares runtime dependencies including `bash`, `jq`, `whiptail`, `sudo`, `systemd`, `iproute2`, `gpg`, `python3-yaml`, `rsync`, `parted`, `dosfstools`, `e2fsprogs`, `btrfs-progs`, `f2fs-tools`, and `ntfs-3g`.

## Continuous Integration

CI is driven by GitHub Actions workflows under `.github/workflows/` covering JSON validation, shell linting, coding style, bats tests, Debian packaging, documentation builds, label sync, PR triage, and a periodic desktop matrix audit.

For an overview of workflow status for this repository, see the Armbian CI dashboard:

<https://actions.armbian.com/?repo=configng>

## Contribute

Want to add a new software title, improve a configuration module, or introduce entirely new functionality? Contributions are welcome.

See [`CONTRIBUTING.md`](CONTRIBUTING.md) and the project's contributor documentation:

<https://docs.armbian.com/Contribute/Armbian-config>

> 📌 Tip: Keep changes modular — it makes review and merging faster.

Please also read our [Code of Conduct](CODE_OF_CONDUCT.md).

## Support

- **Community Forums** — <https://forum.armbian.com>
- **Discord / IRC / Matrix Chat** — <https://docs.armbian.com/Community_IRC/>
- **Paid Consultation** — <https://www.armbian.com/contact>

## Contributors

Thanks to all who have contributed to Armbian Config!

<a href="https://github.com/armbian/configng/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=armbian/configng" />
</a>
<br>
<br>

## Armbian Partners

Armbian's [partnership program](https://forum.armbian.com/subscriptions) helps to support Armbian and the Armbian community. Please take a moment to familiarize yourself with [our Partners](https://armbian.com/partners).

## License

Armbian Config is distributed under the **GNU General Public License v3.0**. See [`LICENSE`](LICENSE) for the full text.
