<p align="center">
    <img src="https://raw.githubusercontent.com/armbian/build/main/.github/armbian-logo.png" alt="Armbian logo" width="144">
</p>
<div align="center">

[![CodeFactor](https://www.codefactor.io/repository/github/tearran/configng/badge)](https://www.codefactor.io/repository/github/tearran/configng)
[![GitHub last commit (branch)](https://img.shields.io/github/last-commit/Tearran/configng/main)](https://github.com/Tearran/configng/commits)
[![Join the Discord](https://img.shields.io/discord/854735915313659944.svg?color=7289da&label=Discord%20&logo=discord)](https://discord.com/invite/gNJ2fPZKvc)

</div>

# Armbian configuration

## Codename Configng
Under development

## Overview
This document discusses establishing a `armbian-config` set of binary tools To configure Armbian build
## Design
A modular design is used, with a focus on making it easy to add new software titles or functionality. A combination of grouped functions in `/lib` and binary tools in `/bin` is used.

## Tools
- [[armbian-lib]](https://github.com/Tearran/configng/wiki/library) armbian-config library of grouped functions
- [[armbian-config]](https://github.com/Tearran/configng/wiki/config) tool is used for the CLI.
- [[others]](#) coming soon

## Help messages 
Help messages  for each command are accessible from the CLI `config -h`



# User guide
## Quick start
### Installation Options
Our applications support two Run styles

## Limitations 
<!-- For guidance on these best practices, refer to [insert relevant resources or links]. -->
- functionaly may or may not work when not useing administration privileges
  - Lager sample size needed
- armbian-configng does not requier adnistation access. 
  - Fallbacks need to be set for admin and no admn access.
- Non admin is limited to --dev

  

1. **Run from GitHub repository:**
   
   ` sudo apt update && sudo apt install git `
   
    ```bash

    cd ~/
    git clone https://github.com/armbian/configng.git
    cd configng
    ./bin/armbian-configng --dev
    ```

    To uninstall:

    ```bash
    cd ~/
    # rm -rf configng
    ```

3. **Install from a .deb package:**
    [Disclamer](#disclaimer): Not recomened

   <!-- generated readme allowed for dynamic links to be use with safer option of wget" -->
   
    ```bash
    {  
    latest_release=$(curl -s https://api.github.com/repos/armbian/configng/releases/latest)
    deb_url=$(echo "$latest_release" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')
    curl -LO "$deb_url"
    deb_file=$(echo "$deb_url" | awk -F"/" '{print $NF}')
    sudo dpkg -i "$deb_file"
    sudo dpkg --configure -a
    sudo apt --fix-broken install  
    }
    ```

    To uninstall:

    ```bash
    sudo dpkg -r armbian-configng
    ```
    or
    ```bash
      sudo apt remove armbian-configng
    ```
4. **Install from the Armbian repository(Coming Soon):**

    ```bash
    echo "deb [signed-by=/usr/share/keyrings/armbian.gpg] https://armbian.github.io/configng stable main" \
    | sudo tee /etc/apt/sources.list.d/armbian-development.list > /dev/null
    sudo apt update
    sudo apt install armbian-configng
    ```

    To uninstall:

    ```bash
    {  sudo apt remove armbian-configng
    # sudo rm /etc/apt/sources.list.d/armbian-development.list
    sudo apt update  }
    ```

### Using Options

Our applications support two styles of options:

1. **C-style commands:** The `help` command provides a message with examples of how of use.
2. These option bypass user interations
3. Limitations
  a. small sample size
    - Not much error handeling
    - Two way communication layer placeholder need filling


    ```bash
    ./bin/armbian-configng help
    ```

5. **Script-style options:** These are passed as `-option` or `--option`. For example, to request help, you would use `-h` or `--help`.

    ```bash
    ./bin/armbian-configng -h
    ./bin/armbian-configng --help
    ```

## Disclaimer

This guide includes the use of `curl` command to download files from the internet. While we strive to provide safe and reliable instructions, we cannot guarantee the safety of any files downloaded using `curl`. 

Please ensure that you trust the source of the files you are downloading. Be aware that downloading files from the internet always carries a risk, and you should only download files from trusted sources.

Always review the scripts and commands you run in your terminal. If you don't understand what a command or script does, take the time to learn about it before running it. This can help prevent unexpected behavior or damage to your system.
