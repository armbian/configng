<p align="center">
  <a href="#build-framework">
  <img src="https://raw.githubusercontent.com/armbian/configng/main/share/icons/hicolor/scalable/configng-tux.svg" width="128" alt="Armbian Config NG Logo" />
  </a><br>
  <strong>Armbian Config: The Next Generation</strong><br>
<br>
<a href=https://github.com/armbian/configng/actions/workflows/debian.yml><img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/armbian/configng/debian.yml?logo=githubactions&label=Packaging&style=for-the-badge&branch=main"></a> <a href=https://github.com/armbian/configng/actions/workflows/unit-tests.yml><img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/armbian/configng/unit-tests.yml?logo=githubactions&label=Unit%20tests&style=for-the-badge&branch=main"></a> <a href=https://github.com/armbian/configng/actions/workflows/docs.yml><img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/armbian/configng/docs.yml?logo=githubactions&label=Documentation&style=for-the-badge&branch=main"></a>
</p>

**armbian-config** provides configuration and installation routines for customizing and automating tasks within Armbian Linux environment. These utilities help streamline setup processes for various use cases.

## Getting Started

**Armbian-config** comes preinstalled with Armbian. To get started, open a terminal or log in via SSH, then run:

```bash
armbian-config
```

<a href=#><img src=.github/images/common.png></a>

## Key Advantages
- **Lightweight**: Minimal dependencies for optimal performance.
- **Flexible**: Supports JSON, TUI, CLI, and API interfaces.
- **Modern**: A fresh approach to configuration.
- **Low entropy**: Byte clean uninstall for most targets.

## Features

- **System Configuration**: 
  - Kernel management, headers, hardware tweaks.
  - NFS and ZFS storage management.
  - SSH user access tweaks.
  - System updates, rolling / stable, containers update.
- **Network Management**: 
  - Fixed / dynamic IP configuration.
  - Connecting to wireless network.
  - Access point management.
- **Localization Settings**: 
  - Configure time zone.
  - Set language and locales.
  - Change hostname.
- **Software Management**:
  - Software installation and removal.
  - Native and containerized environment.
  - Standardised, updatable, maintained.

## Compatibility

This tool is optimized for use with [**Armbian Linux**](https://www.armbian.com), but in theory, it should also work on any systemd-based, APT-compatible Linux distribution — including Linux Mint, Elementary OS, Kali Linux, MX Linux, Parrot OS, Proxmox, Raspberry Pi OS, and others.
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
```

```bash
armbian-config
```
</details>

## Contributing

<a href="https://github.com/armbian/configng/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=armbian/configng" />
</a>
<br>
<br>

Thank you to everyone who has contributed to **Armbian-config** — your efforts are deeply appreciated!

#### General

Contributions are welcome in many forms:

- 🐞 [Report bugs](https://github.com/armbian/configng/issues)
- 📚 [Improve documentation](https://docs.armbian.com/)
- 🛠️ [Fix or enhance code](https://github.com/armbian/configng/pulls)

Please read our [CONTRIBUTING.md](./CONTRIBUTING.md) before getting started.

#### Adding or configuring functionality

Want to expand Armbian-config with new features or tools? Whether you're adding a new software title, enhancing an existing configuration module, or introducing entirely new functionality, we welcome your ideas and code.

To get started:

- Review how similar features are implemented in the current codebase.
- Follow the structure and coding style used in existing modules.
- Ensure your additions are well-tested and don’t break existing functionality.
- Document any new options clearly so users understand how to use them.

<https://docs.armbian.com/Contribute/Armbian-config>

> 📌 Tip: Keep your changes modular and easy to maintain — this helps us review and merge your contribution faster.

#### 💖 Donating

Not a developer? You can still make a big impact! Your donations help us maintain infrastructure, test hardware, and improve development workflows.

[Support the project here](https://github.com/sponsors/armbian)

## License

(c) [Contributors](https://github.com/armbian/configng/graphs/contributors)

All code is licensed under the GPL, v3 or later. See [LICENSE](LICENSE) file for details.
