# Tools Directory


This folder contains scripts for managing files for the armbian-config project.

- [config-jobs](#config-jobs) - Split and rejoin project JSON files
- [config-markdown.py](#config-dynamic-doc) - Generate documentation for armbian-config based on an external JSON configuration

## Overview


### config-jobs

The `config-jobs` script allows you to split a large JSON file into smaller parts or rejoin multiple JSON files into a single file.

#### Dependencies

- [GNU bash](https://www.gnu.org/software/bash/) is required to run the script.
- [jq](https://stedolan.github.io/jq/) is used for JSON processing.

#### Example Usage

To split a JSON file:
```
./config-jobs -s input.json
```

To join multiple JSON files into a single file:
```
./config-jobs -j output.json
```

---

### config-dynamic-doc

The `config-dynamic-doc` script generates both technical and user-focused Markdown documentation from an external JSON configuration. The generated documentation files are saved in the `docs` directory, with separate Markdown files for each item in the JSON configuration.

#### Usage
```
python3 config-dynamic-doc.py
```

The script expects the JSON file to be located at:
```
../lib/armbian-configng/config.ng.jobs.json
```

#### What It Does
- Creates navigation links (table of contents) for all IDs and descriptions.
- Generates technical documentation that includes commands, prompts, conditions, author information, and status.
- Creates user-focused documentation with simplified instructions.
- Includes custom header, footer and section image:

	```
	- tools/include/markdown/ID-header.md
	- tools/include/markdown/ID-footer.md
	- tools/include/images/ID.png
	```

#### Dependencies

- [Python 3](https://www.python.org/) with the standard libraries `json` and `os`.

#### Example Usage

To generate Markdown documentation:
```
python3 config-dynamic-doc.py
```

Markdown files will be created in the `docs` directory.
