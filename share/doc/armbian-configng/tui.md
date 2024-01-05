# Armbian tui 
 
[Text-based user interface](https://en.wikipedia.org/wiki/Text-based_user_interface) design to utilizes gnu bash modular system already in place 

Common example: 

- `  | grep ` 
- `cat file`
- `<< EOF` 
- `  | sed '..'` 

### Dependancy
- GNU bash shell
- awk
- dialog TUI

#### Optional: 
- newt whiptail

```bash
sudo apt update && sudo apt install whiptail
```

## Help Message cli
`tui -h`
```bash
Usage: [command] | tui [ -h | -m | -o ]
Options:
  -h,     Print this help.

  -o,     Opens an OK message Box

  -m,     Opens an Menu select Box.

  -p,     Opens Popup message box.

```
## Ok message box
`tui -o `

### Example: echo
```bash 
echo "this is tui ok window" | tui -o
```
<img width="782" alt="image" src="https://github.com/Tearran/configng/assets/2831630/33153f93-e704-4e39-bd74-99ec4698e82a">


### Example: system tool
```bash 
 systemd-analyze | tui -o
```
<img width="782" alt="image" src="https://github.com/Tearran/configng/assets/2831630/c94041c0-ba2d-44db-87d1-104c8495f382">

## Menu selection box
`tui -m `

### Example: Menu list followed by ok message.
```bash 
apt-cache search desktop | grep -i -e "\-desktop-full " -e "\-desktop-environment " | awk -F "- " '{print $1, $2}' | tui -m | tui -o
```

https://github.com/Tearran/configng/assets/2831630/960d640f-a801-4e6e-90f0-39fb6d952b10


- [bash manual](https://www.gnu.org/software/bash/manual/bash.html)
- [zsh conditional expressions](https://zsh.sourceforge.io/Doc/Release/Conditional-Expressions.html)
- [pretty dialog boxes](https://gijs-de-jong.nl/posts/pretty-dialog-boxes-for-your-shell-scripts-using-whiptail/)