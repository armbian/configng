<p align="center">
  <a href="#build-framework">
   <img src="https://raw.githubusercontent.com/armbian/build/master/.github/armbian-logo.png" alt="Armbian logo" width="144">
  </a><br>
  <strong>Armbian Configuration Utility</strong><br>
<br>
<a href=https://github.com/armbian/configng/actions/workflows/debian.yml><img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/armbian/configng/debian.yml?logo=githubactions&label=Packaging&style=for-the-badge&branch=main"></a> <a href=https://github.com/armbian/configng/actions/workflows/unit-tests.yml><img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/armbian/configng/unit-tests.yml?logo=githubactions&label=Unit%20tests&style=for-the-badge&branch=main"></a> <a href=https://github.com/armbian/configng/actions/workflows/docs.yml><img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/armbian/configng/docs.yml?logo=githubactions&label=Documentation&style=for-the-badge&branch=main"></a>
</p>


## What does this project do?

The Armbian Configuration Utility is a command-line, TUI and GUI tool designed for configuring Armbian boards and managing system settings.

It is divided into four main categories:

- Network Settings
- Localization Options
- Software Management
- System Configuration

## Run rolling release

Requirements: Debian or Ubuntu based Armbian Linux.

```
echo "deb [signed-by=/usr/share/keyrings/armbian.gpg] \
https://armbian.github.io/configng stable main" \
| sudo tee /etc/apt/sources.list.d/armbian-development.list > /dev/null  
sudo apt update && sudo apt install armbian-configng
```

For more information download and see
```
sudo armbian-configng --help
```
