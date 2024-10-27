# Tools Directory


This folder contains scripts for managing files for the armbian-config project.

- [config-markdown.py](#config-markdown.py) - Generate documentation for armbian-config based on an external JSON configuration

## Overview


### config-markdown.py

The `config-dynamic-doc` script generates both technical and user-focused Markdown documentation from an external JSON configuration. The generated documentation files are saved in the `docs` directory, with separate Markdown files for each item in the JSON configuration.

#### Usage

The script expects the JSON file to be located at `../lib/armbian-config/config.jobs.json`
```
python3 config-markdown.py -h
```
```
Error: The configuration file 'config.jobs.json' was not found.
Please run 'config_assemble.sh` `-p` or `-t' first.
```
or
```
python3 config-markdown.py -h
```
```
Usage: config-markdown [-u|-t]
Options:
  -u  Generate user documentation
  -t  Generate technical documentation
  ```


#### What It Does
- ~~Creates navigation links (table of contents) for all IDs and descriptions.~~
- Generates technical documentation that includes commands, prompts, conditions, author information, and status.
- Creates user-focused documentation with simplified instructions.
- Includes custom header, footer and section image:

	```
	- tools/include/markdown/ID-header.md
	- tools/include/markdown/ID-footer.md
	- tools/include/images/ID.png
	```

#### Dependencies

- [Python 3](https://www.python.org/) with the standard libraries `json`, `sys`, `argparse`, and `os`.

#### Example Usage

Markdown files will be created in the `docs` directory.
