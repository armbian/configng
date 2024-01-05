# Under construction
# Config Development Environment

## Operating System
- Armbian GNU Linux

## Shell
- GNU bash

## Programming Languages
- GNU bash

## Dev Directory Structure
see [Naming-Convention](https://github.com/Tearran/configng/wiki/Naming-Convention) for filenames

## Minimum dev Requirements
- GNU Linux compatible text editor
- git
- Github account

## Optional Tools
- equivs-build
- whiptail
- Visual Studio Code

# deb
## Packages
### equivs-build

equivs-build is often used when you want to create a simple package to satisfy dependencies or to register locally installed software with the package manager

Install `equivs` package if you don't have it already installed:
```
sudo apt-get install equivs
```

Change to the `~/.local/armbian-all-package-dumb` directory:
```
mkdir -p ~/.local/src/armbian-all-package-dumb
cd ~/.local/src/armbian-all-package-dumb
```

Create a control file for your package using the `equivs-control` command. This command will create a template control file named `mypackage` that you can then edit to customize your package:
```
equivs-control armbian-<$TBT>-catagory-name
```

4. Edit the `mypackage` control file using your preferred text editor. In this file, you can specify the package name, version, dependencies, and other information about your package. Here is an example of a simple control file for a package named `mypackage` with version `1.0` that depends on the `libc6` package:
```
### Commented entries have reasonable defaults.
### Uncomment to edit them.
# Source: <source package name; defaults to package name>
Section: misc
Priority: optional
# Homepage: <enter URL here; no default>
Standards-Version: 3.9.2

Package: mypackage
Version: 1.0
Depends: libc6
# Recommends: <comma-separated list of packages>
# Suggests: <comma-separated list of packages>
# Provides: <comma-separated list of packages>
# Replaces: <comma-separated list of packages>
# Architecture: all
Description: short description of mypackage
 long description of mypackage
 .
 second paragraph of long description
```

5. Build the package using the `equivs-build` command:
```
equivs-build mypackage
```

This will create a `.deb` file in the current directory, which you can then install using the `dpkg` command.



<!-- ## Repository
### reprepro 
[reprepro](https://www.linuxbabe.com/linux-server/set-up-package-repository-debian-ubuntu-server)
is tool to manage a repository of Debian packages. It can be used to create and maintain a simple repository of packages that can be accessed using the APT package manager .

Here are the steps to set up a Debian APT repository using `reprepro`:
 Install `reprepro`:
```
sudo apt install reprepro
```

2. Create a base directory for the repository:
```
sudo mkdir -p /var/www/repository/
```
3. Configure `reprepro` by creating a `conf` directory inside the base directory and creating two files: `distributions` and `options`. The `distributions` file defines the distributions and components that your repository will support, while the `options` file contains global options for `reprepro`. Here is an example of how you can create and edit these files using the `nano` text editor:

- Create the `conf` directory:
```
sudo mkdir /var/www/repository/conf
```

- Create and edit the `distributions` file:
```
sudo nano /var/www/repository/conf/distributions
```
In the `nano` editor, you can enter the following content for a simple `distributions` file that defines a single distribution named `mydistro` with a single component named `main`:
```
Origin: My Repository
Label: My Repository
Codename: mydistro
Architectures: i386 amd64
Components: main
Description: My personal APT repository
SignWith: yes
```
Press `Ctrl + O` to save the file, then press `Ctrl + X` to exit the editor.

- Create and edit the `options` file:
```
sudo nano /var/www/repository/conf/options
```
In the `nano` editor, you can enter the following content for a simple `options` file that sets the default basedir for the repository:
```
basedir /var/www/repository/
```
Press `Ctrl + O` to save the file, then press `Ctrl + X` to exit the editor.


4. Add packages to the repository using the `reprepro includedeb` command.

5. Configure your APT sources to use the new repository by adding an entry to your `/etc/apt/sources.list` file or by creating a new file in `/etc/apt/sources.list.d/`.
-->

# Sources
From 8/8/2023

- https://manpages.debian.org/testing/equivs/equivs-build.1.en.html
- https://www.linuxbabe.com/linux-server/set-up-package-repository-debian-ubuntu-server.
- https://wiki.debian.org/DebianRepository/Setup.
- https://debian-handbook.info/browse/stable/sect.setup-apt-package-repository.html.
- https://debian-handbook.info/browse/stable/sect.building-first-package.html
- https://www.itzgeek.com/how-tos/linux/debian/setup-debian-11-official-repository-in-sources-list-etc-apt-sources-list.html.
- https://www.dynamsoft.com/codepool/linux-debian-reporisory-reprepro.html.
- http://example.org/debian.
- https://hub.docker.com/r/spotify/debify/.
- http://packages.falcot.com/.