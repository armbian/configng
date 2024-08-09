# Armbian Configuration Utility
Utility for configuring your board, adjusting services, and installing applications.

Armbian-configng User selection is divided into four main sections:
- **System**: System and security settings.
- **Network**: Wired, wireless, Bluetooth, access point.
- **Localisation**: Timezone, language, hostname.
- **Software**: System and third-party software install.

### Development

Development is divided into three sections:
- **Jobs - JSON Object**
  - Defines various tasks and their parameters in a JSON file.
  - Location: `lib/armbian-configng/config.ng.jobs.json`
- **Helpers - Bash Functions**
  - Contains reusable Bash functions to support various operations.
    - Core functions: `lib/armbian-configng/config.ng.functions.sh`
    - Documentation functions: `lib/armbian-configng/config.ng.docs.sh`
    - Network functions: `lib/armbian-configng/config.ng.network.sh`
- **Runtime - Board Statuses**
  - Utilizes [jq](https://stedolan.github.io/jq/) (a lightweight and flexible command-line JSON processor) job definitions to monitor and manage board statuses.
  - Location: `lib/armbian-configng/config.ng.jobs.json`

## Testing and Contributing

### Development

**Git Development and Contribution:**
~~~bash
git clone https://github.com/armbian/configng
cd configng
./armbian-configng --help
~~~

**Install the dependencies:**
~~~bash
sudo apt install git jq whiptail
~~~

**Make changes, test, and update documents:**
(Note: `sudo` is not used for development.)
~~~bash
armbian-configng --doc
~~~

### Tools

Included is a module generator located at `tools/index.html`. For more details, refer to the [README in the tools directory](./tools/README.md).