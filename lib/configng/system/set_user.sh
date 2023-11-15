This is a refactoring of [armbian-config](https://github.com/armbian/config) using [Bash Utility](https://labbots.github.io/bash-utility)
embedded in this project. This allows for functional programming in Bash. Error handling and validation are also included.
The idea is to provide an API in Bash that can be called from a Command line interface, Text User interface and others.
Why Bash? Well, because it's going to be in every distribution. Striped down distributions
may not include Python, C/C++, etc. build/runtime environments

## Quick start
Run the following commands:

        sudo apt install git
        cd ~/
        git clone https://github.com/armbian/configng.git
        bash ~/configng/bin/armbian-configng -h
  
### If all goes well you should see the help message

## Coding Style
follow the following coding style:

    # @description A short description of the function.
    #
    # @exitcode 0  If successful.
    #
    # @options A description if there are options.
    function group::string() {
        echo "hello world"
        return 0
    }
  
# Codestyle can be used to auto generate
 - Markdown
 - JSON
 - Text User Interface
 - Command Line Interface
 - Help message
 - launch a feature