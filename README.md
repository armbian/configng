
<p align="center">
    <img src="https://raw.githubusercontent.com/armbian/build/main/.github/armbian-logo.png" alt="Armbian logo" width="144">
    <br>
    Armbian ConfigNG 
    <br>
    <a href="https://www.codefactor.io/repository/github/tearran/configng"><img src="https://www.codefactor.io/repository/github/tearran/configng/badge" alt="CodeFactor" /></a>
</p>

# User guide
## Quick start


### Installation Options

There are three ways to install `armbian-configng`:

1. **Install from the GitHub repository:**

    ```bash
    sudo apt install git
    cd ~/
    git clone https://github.com/armbian/configng.git
    cd configng
    ./bin/armbian-configng --dev
    ```

    To uninstall:

    ```bash
    cd ~/
    rm -rf configng
    ```

2. **Install from a .deb package:**

    ```bash
    latest_release=$(curl -s https://api.github.com/repos/armbian/configng/releases/latest)
    deb_url=$(echo "$latest_release" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')
    curl -LO "$deb_url"
    deb_file=$(echo "$deb_url" | awk -F"/" '{print $NF}')
    sudo dpkg -i "$deb_file"
    sudo apt --fix-broken install
    ```

    To uninstall:

    ```bash
    sudo dpkg -r armbian-configng
    ```

3. **Comming to a Armbian repository near you:**

    ```bash
    echo "deb [signed-by=/usr/share/keyrings/armbian.gpg] https://armbian.github.io/configng stable main" \
    | sudo tee /etc/apt/sources.list.d/armbian-development.list > /dev/null
    sudo apt update
    sudo apt install armbian-configng
    ```

    To uninstall:

    ```bash
    sudo apt remove armbian-configng
    sudo rm /etc/apt/sources.list.d/armbian-development.list
    sudo apt update
    ```

Please choose the option that best suits your needs.

## Coding Style
follow the following coding style:
~~~
# @description A short description of the function.
#
# @exitcode 0  If successful.
#
# @options A description if there are options.
function group::string() {s
    echo "hello world"
    return 0
}
~~~
