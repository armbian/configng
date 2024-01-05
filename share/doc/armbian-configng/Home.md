![image](https://github.com/Tearran/configng/assets/2831630/43316906-ccc7-4b5d-8214-2514681377b4)

[![GitHub last commit (branch)](https://img.shields.io/github/last-commit/Tearran/configng/main)](https://github.com/Tearran/configng/commits)
[![Join the Discord](https://img.shields.io/discord/854735915313659944.svg?color=7289da&label=Discord%20&logo=discord)](https://discord.com/invite/gNJ2fPZKvc)

Armbian utilities

## Codename Configng
Under development

## Overview
This document discusses establishing a set of binary tools while the refactoring of `armbian-config`
## Design
A modular design is used, with a focus on making it easy to add new software titles or functionality. A combination of grouped functions in `/lib` and binary tools in `/bin` is used. Suggested that the tools be classified as `armbian-tools`, `armbian-utilities`, or similar for later packaging.

## The current focus:
- library, Desktop Installs  [[wiki]](https://github.com/Tearran/configng/wiki/library)
- wki, Naming Convention [[wiki]](https://github.com/Tearran/configng/wiki/Naming-Convention)

## Tools
- [[armbian-lib]](https://github.com/Tearran/configng/wiki/library) armbian-config library of grouped functions
- [[armbian-config]](https://github.com/Tearran/configng/wiki/config) tool is used for the CLI.
- [[armbian-tui]](https://github.com/Tearran/configng/wiki/tui)  A TUI frontend for `config`.
- [[armbian-monitor]](https://github.com/Tearran/configng/wiki/monitor) System benchmarks and report tool.
- [[others]](#) coming soon

## Help messages 
Help messages  for each command are accessible from the CLI `config -h`
