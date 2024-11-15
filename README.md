<p align="center">
  <a href="#build-framework">
  <img src="https://raw.githubusercontent.com/armbian/configng/main/share/icons/hicolor/scalable/configng-tux.svg" width="128" alt="Armbian Config NG Logo" />
  </a><br>
  <strong>Armbian Config: The Next Generation</strong><br>
<br>
<a href=https://github.com/armbian/configng/actions/workflows/debian.yml><img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/armbian/configng/debian.yml?logo=githubactions&label=Packaging&style=for-the-badge&branch=main"></a> <a href=https://github.com/armbian/configng/actions/workflows/unit-tests.yml><img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/armbian/configng/unit-tests.yml?logo=githubactions&label=Unit%20tests&style=for-the-badge&branch=main"></a> <a href=https://github.com/armbian/configng/actions/workflows/docs.yml><img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/armbian/configng/docs.yml?logo=githubactions&label=Documentation&style=for-the-badge&branch=main"></a>
</p>


> Note: Some references may still use the old name during the transition period.

armbian-config provides configuration scripts for customizing and automating tasks within Armbian environments. These scripts help streamline setup processes for various configurations and use cases.

## Features

- **System Configuration**: Automate system-level settings, including hardware configuration and performance tuning.
- **Network Management**: Manage network settings such as IP configuration, Wi-Fi, and other connectivity options.
- **Localization Settings**: Configure time zone, language, and other localization preferences.
- **Software Installation/Uninstallation**: Simplify software management, including installing or removing packages as needed.

## Compatibility

This tool is tailored to works best with [**Armbian Linux**](https://www.armbian.com) but it has also been automatically tested on **Debian Bookworm**, **Ubuntu Jammy** and **Ubuntu Noble**. In theory it should work on all apt based Linux distributions.

## Key Advantages
- **Extremely Lightweight**: Minimal dependencies for optimal performance.
- **Redesigned from Scratch**: A fresh approach to configuration.
- **Flexible Menu Structure**: Supports JSON, TUI, CLI, and API interfaces.

## Getting Started
We expect to deploy this tool in production with the upcoming release. Your help with testing and completion is invaluable!

### Clone and run
Run the following commands in your terminal:

```bash
git clone https://github.com/armbian/configng
cd configng
tools/config-assemble.sh -p # Use -t for testing
sudo bin/armbian-config
```

### Install from Development Repository
Run the following commands in your terminal:

```bash
echo "deb [signed-by=/usr/share/keyrings/armbian.gpg] https://github.armbian.com/configng stable main" | sudo tee /etc/apt/sources.list.d/armbian-development.list > /dev/null
sudo apt update
sudo apt -y install armbian-config
```

## Contributing

Contributions are welcome! Please refer to general [CONTRIBUTING.md](CONTRIBUTING.md) and guidelines for [adding a new feature](https://docs.armbian.com/User-Guide_Armbian-Software/#adding-example).

## Support Us

Join the community and be a part of Armbian userspace testing and development.

- **Discord**: [invite](https://discord.com/invite/armbian)
- **Forums**: [Join us](https://forum.armbian.com/)
- **IRC**: [how to](https://docs.armbian.com/Community_IRC/)

- **Donate**: [Armbian](https://www.armbian.com/donate/)
- **Sponsor**: [Sponsor Armbian](https://github.com/sponsors/armbian)
- **Subscribe**: [Armbian Forum Subscriptions](https://forum.armbian.com/subscriptions/)

