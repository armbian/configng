
# Armbian Build System User Manual

## NAME

**armbian-build** - Armbian Build System

## SYNOPSIS

armbian-build [OPTIONS] [TARGET]


## DESCRIPTION

The **armbian-build** command is the entry point for the Armbian Build System, which allows you to create customized Linux distributions for ARM-based single-board computers (SBCs). This user manual provides detailed information on how to use the build system to generate customized images and optimize them for your target hardware.

## OPTIONS

- `-h`, `--help`
   Display this help message and exit.
   
- `-v`, `--version`
   Display the version of the Armbian Build System.

- `-c`, `--config CONFIG_FILE`
   Use a custom configuration file (if not specified, the default configuration is used).

- `-p`, `--prepare`
   Prepare the build environment by installing necessary packages and dependencies.

- `-b`, `--build`
   Start the build process for the specified target.

- `-i`, `--image`
   Generate an SD card image for the specified target.

- `-u`, `--update`
   Update the Armbian Build System to the latest version.

- `-l`, `--list-targets`
   List available build targets and their descriptions.

## TARGET

The **TARGET** argument specifies the build target, which defines the desired distribution and hardware platform. This can be a board name or an alias as defined in the configuration file.

## EXAMPLES

1. Display the help message:
   ```
   armbian-build -h
   ```

2. Build an image for the Orange Pi PC board:
   ```
   armbian-build -b sunxi -p orangepipc
   ```

3. Generate an SD card image for the Raspberry Pi 4:
   ```
   armbian-build -i buster -b raspberrypi4
   ```

## CONFIGURATION
For advanced customization and configuration options, refer to the configuration file located at `/etc/armbian-build.conf`. This file allows you to define custom settings and parameters for your build process.

## SEE ALSO

  [Armbian Documentation](https://docs.armbian.com/)
  
  [Armbian Community Forum](https://forum.armbian.com/)

## AUTHOR

Armbian Build System is maintained by the Armbian community.

## REPORTING BUGS

Report bugs and issues at the [Armbian GitHub repository](https://github.com/armbian/build/issues).

---

This template provides an outline for documenting the Armbian Build System in Section 1. 
You can adapt and expand it to include more specific details about the available options, targets, and usage examples.
Additionally, make sure to include any relevant links to the official documentation and support channels.
