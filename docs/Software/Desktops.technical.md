- [Desktop Environments](#desktops)
  - [XFCE desktop](#xfce)
    - [XFCE desktop Install](#de01)
    - [Uninstall](#de02)
    - [Enable autologin](#de03)
    - [Disable autologin](#de04)
  - [Gnome desktop](#gnome)
    - [Gnome desktop Install](#de11)
    - [Uninstall](#de12)
    - [Enable autologin](#de13)
    - [Disable autologin](#de14)
  - [i3-wm desktop](#de20)
    - [i3 desktop Install](#de21)
    - [i3 desktop uninstall](#de22)
    - [Enable autologin](#de23)
    - [Disable autologin](#de24)
  - [Cinnamon desktop](#cinnamon)
    - [Cinnamon desktop Install](#de31)
    - [Cinnamon desktop uninstall](#de32)
    - [Enable autologin](#de33)
    - [Disable autologin](#de34)
  - [Kde-neon desktop](#de40)
    - [Kde-neon desktop Install](#de41)
    - [Uninstall](#de42)
    - [Enable autologin](#de43)
    - [Disable autologin](#de44)
  - [Improve application search speed](#de99)

# Desktops

**description:** Desktop Environments


## XFCE

**description:** XFCE desktop


### DE01

**description:** XFCE desktop Install

**about:** 
Install XFCE:
Xfce is a lightweight desktop environment for UNIX-like operating systems. It aims to be fast and low on system resources, while still being visually appealing and user friendly.

**Command:** 
~~~
manage_desktops 'xfce' 'install'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ ! -f /usr/share/xsessions/xfce.desktop ]
~~~

### DE02

**description:** Uninstall

**Command:** 
~~~
manage_desktops 'xfce' 'uninstall'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/xfce.desktop ]
~~~

### DE03

**description:** Enable autologin

**Command:** 
~~~
manage_desktops 'xfce' 'auto'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/xfce.desktop ] && [ ! -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

### DE04

**description:** Disable autologin

**Command:** 
~~~
manage_desktops 'xfce' 'manual'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/xfce.desktop ] && [ -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

## Gnome

**description:** Gnome desktop


### DE11

**description:** Gnome desktop Install

**Command:** 
~~~
manage_desktops 'gnome' 'install'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ ! -f /usr/share/xsessions/gnome.desktop ]
~~~

### DE12

**description:** Uninstall

**Command:** 
~~~
manage_desktops 'gnome' 'uninstall'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/gnome.desktop ]
~~~

### DE13

**description:** Enable autologin

**Command:** 
~~~
manage_desktops 'gnome' 'auto'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/gnome.desktop ] && ! cat /etc/gdm3/custom.conf 2>/dev/null | grep AutomaticLoginEnable | grep true >/dev/null
~~~

### DE14

**description:** Disable autologin

**Command:** 
~~~
manage_desktops 'gnome' 'manual'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/gnome.desktop ] && cat /etc/gdm3/custom.conf 2>/dev/null | grep AutomaticLoginEnable | grep true >/dev/null
~~~

## DE20

**description:** i3-wm desktop

**Status:** Disabled


### DE21

**description:** i3 desktop Install

**Command:** 
~~~
manage_desktops 'i3-wm' 'install'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ ! -f /usr/share/xsessions/i3.desktop ]
~~~

### DE22

**description:** i3 desktop uninstall

**Command:** 
~~~
manage_desktops 'i3-wm' 'uninstall'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/i3.desktop ]
~~~

### DE23

**description:** Enable autologin

**Command:** 
~~~
manage_desktops 'i3-wm' 'auto'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/i3.desktop ] && [ ! -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

### DE24

**description:** Disable autologin

**Command:** 
~~~
manage_desktops 'i3-wm' 'manual'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/i3.desktop ] && [ -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

## Cinnamon

**description:** Cinnamon desktop


### DE31

**description:** Cinnamon desktop Install

**Command:** 
~~~
manage_desktops 'cinnamon' 'install'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ ! -f /usr/share/xsessions/cinnamon.desktop ] && [ ! -f /usr/share/xsessions/cinnamon2d.desktop ]
~~~

### DE32

**description:** Cinnamon desktop uninstall

**Command:** 
~~~
manage_desktops 'cinnamon' 'uninstall'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/cinnamon.desktop ] || [ -f /usr/share/xsessions/cinnamon2d.desktop ]
~~~

### DE33

**description:** Enable autologin

**Command:** 
~~~
manage_desktops 'cinnamon' 'auto'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/cinnamon.desktop ] && [ ! -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

### DE34

**description:** Disable autologin

**Command:** 
~~~
manage_desktops 'cinnamon' 'manual'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/cinnamon.desktop ] && [ -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

## DE40

**description:** Kde-neon desktop

**Status:** Disabled


### DE41

**description:** Kde-neon desktop Install

**Command:** 
~~~
manage_desktops 'kde-neon' 'install'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ ! -f /usr/share/xsessions/gnome.desktop ]
~~~

### DE42

**description:** Uninstall

**Command:** 
~~~
manage_desktops 'kde-neon' 'uninstall'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/gnome.desktop ]
~~~

### DE43

**description:** Enable autologin

**Command:** 
~~~
manage_desktops 'kde-neon' 'auto'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/gnome.desktop ] && [ ! -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

### DE44

**description:** Disable autologin

**Command:** 
~~~
manage_desktops 'kde-neon' 'manual'
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
[ -f /usr/share/xsessions/gnome.desktop ] && [ -f /etc/lightdm/lightdm.conf.d/22-armbian-autologin.conf ]
~~~

## DE99

**description:** Improve application search speed

**Command:** 
~~~
update-apt-xapian-index -u; sleep 3
~~~

**Author:** @igorpecovnik

**Status:** Stable

**Condition:**
~~~
systemctl is-active --quiet service display-manager
~~~

