# Tools

This folder contains various utility scripts.

## Descriptions

### index.html

A form that will help generate a module for `armbian-config`. The form includes fields for specifying a description and a category, metadata, and bash procedures (commands).

To use, upload to a remote web server or start one of the provided simple servers (python3 required), or visit [armbian.tech](http://armbian.tech).

### server.sh

The `server.sh` script starts a simple Python HTTP server on the first available port in the range 8000-8100. This script is intended for Unix-like systems.

### server.bat

The `server.bat` script starts a simple Python HTTP server on the first available port in the range 8000-8100. This script is intended for Windows systems.

## Requirements

- A javascript compatible web browser (for accessing index.html)
- [armbian.tech](https://armbian.tech/) Web server, or alternatively, Python 3.x (for the simple server)
    
## Usage

### server.sh

To start the server on Unix-like systems, run:

~~~sh
bash ./server.sh
~~~

### server.bat

To start the server on Windows systems, run:

~~~bat
server.bat
~~~