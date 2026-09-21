<h2 align="center">
  <a href=#><img src="https://raw.githubusercontent.com/armbian/.github/master/profile/logosmall.png" alt="Armbian logo"></a>
  <br><br>
</h2>

# Armbian Config (configng)

## Purpose of This Repository

This repository contains the source code for **Armbian Config**, a lightweight configuration utility that simplifies and automates common system tasks on Armbian (and other systemd + APT based Linux distributions). It provides interactive and scriptable routines for initial setup, networking, kernel and firmware management, desktop environments and their branding, and installation of sandboxed server / self-hosted software.

## Quick Start

Armbian Config comes **preinstalled** with Armbian images. To launch:

```bash
armbian-config
```

<a href=#><img src=.github/images/common.png></a>

## Compatibility

Armbian Config is optimized for [**Armbian Linux**](https://www.armbian.com), but in theory it also works on any systemd-based, APT-compatible Linux distribution — including Linux Mint, Elementary OS, Kali Linux, MX Linux, Parrot OS, Proxmox, Raspberry Pi OS, and others.

<details><summary>Add the Armbian key + repository and install the tool</summary>

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
bin/armbian-config            Entry-point script installed as /usr/bin/armbian-config
debian.conf                   Debian packaging metadata used by the CI Debian build
DOCUMENTATION.md              Generated menu / feature reference
share/                        Desktop entry (.desktop) and hicolor icon set
tests/                        Per-module .conf unit tests and bats-based tests
tests/bats/                   Bats test suites and JSON fixtures
tools/                        Build tooling, JSON menu sources and runtime modules
tools/config-assemble.sh      Assembles modules and jobs for production or testing
tools/config-markdown.py      Generates Markdown docs from the assembled JSON
tools/json/                   Menu source JSON (help, localisation, network, software, system, temp)
tools/include/markdown/       Per-item header/footer Markdown snippets used by the doc generator
tools/include/images/         Per-item images embedded into generated documentation
tools/modules/                Runtime shell modules and desktop-related assets
tools/modules/desktops/       Desktop postinst scripts, branding, greeters, skel and helpers
.github/                      Issue / PR templates and CI workflow definitions
```

## Built With

Evidence from the tracked files:

- **Bash / shell scripts** (`bin/armbian-config`, `tools/config-assemble.sh`, `tools/modules/**/*.sh`, `tests/bats/*.bats`) — the main runtime language of the utility.
- **Python 3** (`tools/config-markdown.py`, `tools/modules/desktops/github/audit.py`, `audit_apply.py`, `audit_prompt.py`, `tools/modules/desktops/scripts/parse_desktop_yaml.py`) — documentation generation and desktop matrix tooling; standard-library only for the doc generator, with `pyyaml` used by the desktop audit.
- **JSON** menu definitions under `tools/json/` (`config.help.json`, `config.localisation.json`, `config.network.json`, `config.software.json`, `config.system.json`, `config.temp.json`).
- **Bats** for unit and integration tests under `tests/bats/`, with `jq`, `parted`, `dosfstools` and `ntfs-3g` used by the integration suites.
- **QML** and related assets for the bundled SDDM `plasma-chili` greeter theme under `tools/modules/desktops/greeters/sddm/themes/plasma-chili/`.
- **YAML** for GitHub Actions workflows, issue templates, labels and Dependabot configuration under `.github/`.
- **Debian packaging** via `debian.conf` and the CI Debian build, producing an `armbian-config` `.deb` with dependencies including `bash`, `jq`, `whiptail`, `sudo`, `systemd`, `python3-yaml`, `rsync`, `parted`, `dosfstools`, `e2fsprogs`, `btrfs-progs`, `f2fs-tools` and `ntfs-3g`.

## Building and Testing Locally

Assemble modules and jobs, then run the tool from the working tree:

```bash
tools/config-assemble.sh -p    # -p production, -t testing
bin/armbian-config
```

Generate the documentation (`DOCUMENTATION.md` and per-item Markdown) from the assembled JSON:

```bash
bin/armbian-config --doc
```

Run the bats test suites (matches what CI runs):

```bash
sudo apt-get install -y bats jq parted dosfstools ntfs-3g

# Unit tests (pure functions, no privileges)
bats tests/bats/plan.bats tests/bats/detect.bats tests/bats/detect_windows.bats \
     tests/bats/bootconfig.bats tests/bats/dualboot.bats tests/bats/transfer.bats \
     tests/bats/package.bats tests/bats/runners.bats

# Integration tests (loopback block device + Windows dual-boot; root required)
sudo bats tests/bats/integration_loopback.bats tests/bats/integration_dualboot.bats
```

Per-module functional tests live in `tests/*.conf` — each file defines a `testcase()` function that returns 0 on success. See [tests/README.md](tests/README.md) for the format.

## Documentation

- User-facing menu reference: [DOCUMENTATION.md](DOCUMENTATION.md) (auto-generated by `bin/armbian-config --doc`).
- Contributing to armbian-config: <https://docs.armbian.com/Contribute/Armbian-config>
- Tools overview: [tools/README.md](tools/README.md)

## Continuous Integration

CI status for this repository (build, lint, bats, JSON validation, doc build, desktop audit, and maintenance workflows) is aggregated on the Armbian Actions dashboard:

<https://actions.armbian.com/?repo=configng>

## Contributing

Pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow, and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community expectations. Keep changes modular so they are easy to review and merge.

## Support

- **Community forums:** [forum.armbian.com](https://forum.armbian.com)
- **Chat (Discord / IRC / Matrix, bridged):** [Community Chat](https://docs.armbian.com/Community_IRC/)
- **Paid consultation:** [Contact Armbian](https://www.armbian.com/contact)

## Contributors

Thanks to everyone who has contributed to Armbian Config!

<a href="https://github.com/armbian/configng/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=armbian/configng" />
</a>
<br><br>

## Armbian Partners

Armbian's [partnership program](https://forum.armbian.com/subscriptions) helps support the project and its community. Please take a moment to familiarize yourself with [our Partners](https://armbian.com/partners).

## License

Armbian Config is released under the terms of the [GNU General Public License v3.0](LICENSE).
