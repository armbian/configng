<h2 align="center">
  <a href=#><img src="https://raw.githubusercontent.com/armbian/.github/master/profile/logosmall.png" alt="Armbian logo"></a>
  <br><br>
</h2>

### Purpose of This Repository

This repository contains the source code for **Armbian Config**, a versatile and extremly **lightweight configuration utility** designed to simplify and automate common system tasks within the Armbian Linux environment.

Armbian Config provides interactive and scriptable routines for:

- Initial system setup and personalization  
- Networking configuration, including Wi-Fi, VPN, and static IP  
- Sandboxed software installation and system updates  
- Kernel selection, switching, and firmware management  
- Enabling and managing hardware-specific features  

It is especially useful for single board computers (SBCs), helping users quickly prepare a ready-to-use system without manual intervention.

### Quick Start

Armbian Config comes **preinstalled** with Armbian images.

To launch the utility:

1. Open a terminal (locally or via SSH)
2. Run the following command:

```bash
armbian-config
```

<a href=#><img src=.github/images/common.png></a>

### Compatibility

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
armbian-config
```
</details>

### Contribute

Want to expand **Armbian Config** with new features or tools? Whether you're adding a new software title, enhancing an existing configuration module, or introducing entirely new functionality, we welcome your ideas and code.

<https://docs.armbian.com/Contribute/Armbian-config>

> 📌 Tip: Keep your changes modular and easy to maintain — this helps us review and merge your contribution faster.

### Support

Armbian offers multiple support channels, depending on your needs:

- **Community Forums**  
  Get help from fellow users and contributors on a wide range of topics — from troubleshooting to development.  
  👉 [forum.armbian.com](https://forum.armbian.com)

- **Discord / IRC / Matrix Chat**  
  Join real-time discussions with developers and community members for faster feedback and collaboration.  
  👉 [Community Chat](https://docs.armbian.com/Community_IRC/)

- **Paid Consultation**  
  For advanced needs, commercial projects, or guaranteed response times, paid support is available directly from Armbian maintainers.  
  👉 [Contact us](https://www.armbian.com/contact) to discuss consulting options.

### Contributors

Thanks to all who have contributed to Armbian Config!

<a href="https://github.com/armbian/configng/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=armbian/configng" />
</a>
<br>
<br>

### Armbian Partners

Armbian's [partnership program](https://forum.armbian.com/subscriptions) helps to support Armbian and the Armbian community! Please take a moment to familiarize yourself with [our Partners](https://armbian.com/partners).
