# User Manual generation
Steps To create a comprehensive man page with various sections and formatted content, including usage examples and tutorials, you can follow these steps:

1. **Create Markdown Content:**
   Write the content for your man page in Markdown format, including all the necessary sections, descriptions, usage examples, and tutorials. Make sure to structure the content properly using appropriate Markdown headers (`#`, `##`, `###`, etc.).

```markdown
# ARMBIAN-CONFIG(1) User Manual

## NAME

config - A command line tool for system configuration

## SYNOPSIS

**config** [ -r | Group | option ]

## DESCRIPTION

The `config` command is a command-line tool for system configuration. It provides a range of options for configuring various aspects of the system...

## OPTIONS

- `-h`: Show the help message.
- `-l`: Show a list of available group options.
- ...

## EXAMPLES

To see a list of available desktops to install:


`config install see_desktops`


To enable Infrared Remote Control support:


`config iolocal set_lirc`


## SEE ALSO

Additional documentation for the config command may be available on your system or online.
```

2. **Convert Markdown to Man Page:**
   Use `pandoc` to convert the Markdown content into a formatted man page. You can include metadata and specify the output filename:

	- `sudo apt updated && sudo apt install pandoc`


	- `pandoc --standalone -t man input.md -o output.1`


3. **Add Additional Sections:**
   For more detailed sections like tutorials, additional usage examples, and tutorials, you can use the standard man page sections and headers. Here's an example of how you can add a "TUTORIALS" section:

```md
## TUTORIALS


### Setting Up Wireless Network

To configure a wireless network connection, follow these steps:

1. Run the following command to open the wireless network configuration menu:

  `config -r wireless`

2. Select the appropriate option to enable or disable wireless interfaces...

### Advanced Configuration

For advanced system configuration, you can use the following options...

...
```

4. **Generate the Man Page:**
   Run the `pandoc` command again to generate the man page with the additional sections and tutorials:

   ```bash
   pandoc --standalone -t man input.md -o output.1
   ```

5. **Compress Man Page:**
   If you want to create a compressed man page as `.gz` (common in Debian-based systems), use the `gzip` command:

   ```bash
   gzip output.1
   ```

---
title: ARMBIAN-CONFIG

section: 1

header: User Manual

footer: armbian-config 1.0.0

author: Joey Turner, Tearran

date: August 31, 2023
...