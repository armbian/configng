# NAME
Armbian Build System - Configuration Options

# SYNOPSIS
Armbian build system provides a set of configuration options that can be used with the `./compile.sh` command. These options allow you to customize the build process according to your requirements.

# DESCRIPTION
The following options can be applied to the `./compile.sh` command. They are all optional and can also be added to your build configuration file to save time. Default values are marked in bold if applicable.

## Main Options

- **BUILD_ONLY** (comma-separated list): defines what artifacts should be built. Default value is an empty string, which will build all artifacts.

    - u-boot: build U-Boot
    - kernel: build Kernel
    - armbian-config: build Armbian config
    - armbian-zsh: build Armbian zsh
    - plymouth-theme-armbian: build Armbian Plymouth theme
    - armbian-firmware: build Armbian firmware
    - armbian-bsp: build Armbian board support package
    - chroot: build additional packages
    - bootstrap: build bootstrap package
    - default: build full OS image for flashing

- **KERNEL_ONLY** (yes | no): Warning: This option is deprecated and may be removed in future releases. Use BUILD_ONLY instead.

    - yes: compiles only kernel, U-Boot, and other packages for installation on an existing Armbian system. Note: This will enforce BUILD_ONLY being set as `"u-boot,kernel,armbian-config,armbian-zsh,plymouth-theme-armbian,armbian-firmware,armbian-bsp"`.
    - no: build a complete OS image for writing to an SD card. Note: This will enforce BUILD_ONLY being cleared to an empty string.
    - leave empty to display the selection dialog each time.

...

[Continue with the rest of the content]
