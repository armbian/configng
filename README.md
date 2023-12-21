
<p align="center">
    <img src="https://raw.githubusercontent.com/armbian/build/main/.github/armbian-logo.png" alt="Armbian logo" width="144">
    <br>
    Armbian ConfigNG 
    <br>
    <a href="https://www.codefactor.io/repository/github/tearran/configng"><img src="https://www.codefactor.io/repository/github/tearran/configng/badge" alt="CodeFactor" /></a>
</p>

 # Table of Contents
- [User guide](#user-guide)
  - [Quick start](#quick-start)
    - [Installation Options](#installation-options)
  - [Using Options](#using-options)
  - [Disclamrs](#disclaimer)
  - [Refrance](#referance)

# User guide
## Quick start
### Installation Options
Our applications support two Run styles
1. **Run localy from GitHub repository:**
   ` sudo apt update && sudo apt install git ``
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

2. **Install from a .deb package:**
    [Disclamer](#disclaimer): Not recomened 
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
3. **Install from the Armbian repository(Coming Soon):**

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

    ```bash
    ./bin/armbian-configng help
    ```

2. **Script-style options:** These are passed as `-option` or `--option`. For example, to request help, you would use `-h` or `--help`.

    ```bash
    ./bin/armbian-configng -h
    ./bin/armbian-configng --help
    ```

## Disclaimer

This guide includes the use of `curl` command to download files from the internet. While we strive to provide safe and reliable instructions, we cannot guarantee the safety of any files downloaded using `curl`. 

Please ensure that you trust the source of the files you are downloading. Be aware that downloading files from the internet always carries a risk, and you should only download files from trusted sources.

Always review the scripts and commands you run in your terminal. If you don't understand what a command or script does, take the time to learn about it before running it. This can help prevent unexpected behavior or damage to your system.

## Referance

[curl](https://medium.com/@esotericmeans/the-truth-about-curl-and-installing-software-securely-on-linux-63cd12e7befd)