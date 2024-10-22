- [System wide and admin settings](#system)
  - [Enable Armbian kernel/firmware upgrades](#s01)
  - [Disable Armbian kernel upgrades](#s02)
  - [Edit the boot environment](#s03)
  - [Install Linux headers](#s04)
  - [Remove Linux headers](#s05)
  - [Install to internal storage](#s06)
  - [Manage SSH login options](#ssh)
    - [Disable root login](#s07)
    - [Enable root login](#s08)
    - [Disable password login](#s09)
    - [Enable password login](#s10)
    - [Disable Public key authentication login](#s11)
    - [Enable Public key authentication login](#s12)
    - [Disable OTP authentication](#s13)
    - [Enable OTP authentication](#s14)
    - [Generate new OTP authentication QR code](#s15)
    - [Show OTP authentication QR code](#s16)
    - [Disable last login banner](#s30)
    - [Enable last login banner](#s31)
  - [Change shell system wide to BASH](#s17)
  - [Change shell system wide to ZSH](#s18)
  - [Switch to rolling release](#s19)
  - [Switch to stable release](#s20)
  - [Enable read only filesystem](#s21)
  - [Disable read only filesystem](#s22)
  - [Adjust welcome screen (motd)](#s23)
  - [Install alternative kernels](#s24)
  - [Distribution upgrades](#s25)
    - [Upgrade to latest stable / LTS](#s26)
    - [Upgrade to rolling unstable](#s27)
  - [Manage device tree overlays](#s28)

# System

**description:** System wide and admin settings


## S01

**description:** Enable Armbian kernel/firmware upgrades

**about:** 
This will enable Armbian kernel upgrades.

**Command:** 
~~~
armbian_fw_manipulate unhold
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
[[ -n "$(apt-mark showhold)" ]]
~~~

## S02

**description:** Disable Armbian kernel upgrades

**about:** 
Disable Armbian kernel/firmware upgrades

**Command:** 
~~~
armbian_fw_manipulate hold
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
[[ -z "$(apt-mark showhold)" ]]
~~~

## S03

**description:** Edit the boot environment

**about:** 
This will open /boot/armbianEnv.txt file to edit
CTRL+S to save
CTLR+X to exit
would you like to continue?

**Command:** 
~~~
nano /boot/armbianEnv.txt
~~~

**Author:** 

**Status:** Preview


## S04

**description:** Install Linux headers

**Command:** 
~~~
Headers_install
~~~

**Author:** @Tearran

**Status:** Preview

**Condition:**
~~~
! are_headers_installed
~~~

## S05

**description:** Remove Linux headers

**Command:** 
~~~
Headers_remove
~~~

**Author:** @Tearran

**Status:** Preview

**Condition:**
~~~
are_headers_installed
~~~

## S06

**description:** Install to internal storage

**Command:** 
~~~
armbian-install
~~~

**Author:** https://github.com/igorpecovnik

**Status:** Preview

**Condition:**
~~~
[[ -n $(ls /sbin/armbian-install) ]]
~~~

## SSH

**description:** Manage SSH login options


### S07

**description:** Disable root login

**Command:** 
~~~
sed -i "s|^#\?PermitRootLogin.*|PermitRootLogin no|" /etc/ssh/sshd_config, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q '^PermitRootLogin yes'  /etc/ssh/sshd_config
~~~

### S08

**description:** Enable root login

**Command:** 
~~~
sed -i "s/^#\?PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q '^PermitRootLogin no' /etc/ssh/sshd_config
~~~

### S09

**description:** Disable password login

**Command:** 
~~~
sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q 'PasswordAuthentication yes' /etc/ssh/sshd_config
~~~

### S10

**description:** Enable password login

**Command:** 
~~~
sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config
~~~

### S11

**description:** Disable Public key authentication login

**Command:** 
~~~
sed -i "s/^#\?PubkeyAuthentication.*/PubkeyAuthentication no/" /etc/ssh/sshd_config, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q 'PubkeyAuthentication yes' /etc/ssh/sshd_config
~~~

### S12

**description:** Enable Public key authentication login

**Command:** 
~~~
sed -i "s/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/" /etc/ssh/sshd_config, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q 'PubkeyAuthentication no' /etc/ssh/sshd_config
~~~

### S13

**description:** Disable OTP authentication

**Command:** 
~~~
clear, ! check_if_installed libpam-google-authenticator && ! check_if_installed qrencode || debconf-apt-progress -- apt-get -y purge libpam-google-authenticator qrencode, sed -i "s/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/" /etc/ssh/sshd_config || sed -i "0,/KbdInteractiveAuthentication/s//ChallengeResponseAuthentication yes/" /etc/ssh/sshd_config, sed -i '/^auth required pam_google_authenticator.so nullok/ d' /etc/pam.d/sshd, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q 'ChallengeResponseAuthentication yes' /etc/ssh/sshd_config
~~~

### S14

**description:** Enable OTP authentication

**Command:** 
~~~
check_if_installed libpam-google-authenticator || debconf-apt-progress -- apt-get -y install libpam-google-authenticator, check_if_installed qrencode || debconf-apt-progress -- apt-get -y install qrencode, sed -i "s/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/" /etc/ssh/sshd_config, sed -i $'/KbdInteractiveAuthentication/{iChallengeResponseAuthentication yes\n:a;n;ba}' /etc/ssh/sshd_config || sed -n -i '/password updating/{p;:a;N;/@include common-password/!ba;s/.*\n/auth required pam_google_authenticator.so nullok\nauth required pam_permit.so\n/};p' /etc/pam.d/sshd, [ ! -f /root/.google_authenticator ] && qr_code generate, systemctl restart sshd.service 2>/dev/null | systemctl restart ssh.service 2>/dev/null
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed libpam-google-authenticator || ! check_if_installed qrencode || grep -q '^ChallengeResponseAuthentication no' /etc/ssh/sshd_config || ! grep -q 'ChallengeResponseAuthentication' /etc/ssh/sshd_config
~~~

### S15

**description:** Generate new OTP authentication QR code

**Command:** 
~~~
qr_code generate
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q '^ChallengeResponseAuthentication yes' /etc/ssh/sshd_config
~~~

### S16

**description:** Show OTP authentication QR code

**Command:** 
~~~
qr_code
~~~

**Author:** Igor Pecovnik

**Status:** Preview

**Condition:**
~~~
grep -q '^ChallengeResponseAuthentication yes' /etc/ssh/sshd_config && [ -f /root/.google_authenticator ]
~~~

### S30

**description:** Disable last login banner

**Command:** 
~~~
sed -i "s/^#\?PrintLastLog.*/PrintLastLog no/" /etc/ssh/sshd_config, systemctl restart ssh.service 
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q '^PrintLastLog yes' /etc/ssh/sshd_config
~~~

### S31

**description:** Enable last login banner

**Command:** 
~~~
sed -i "s/^#\?PrintLastLog.*/PrintLastLog yes/" /etc/ssh/sshd_config, systemctl restart ssh.service 
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
grep -q '^PrintLastLog no' /etc/ssh/sshd_config
~~~

## S17

**description:** Change shell system wide to BASH

**Command:** 
~~~
export BASHLOCATION=$(grep /bash$ /etc/shells | tail -1), sed -i "s|^SHELL=.*|SHELL=${BASHLOCATION}|" /etc/default/useradd, sed -i "s|^DSHELL=.*|DSHELL=${BASHLOCATION}|" /etc/adduser.conf, apt_install_wrapper apt-get -y purge armbian-zsh zsh-common zsh tmux, update_skel, awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534 || $3 == 0) print $1}' /etc/passwd | xargs -L1 chsh -s $(grep /bash$ /etc/shells | tail -1)
~~~

**Author:** https://github.com/igorpecovnik

**Status:** Preview

**Condition:**
~~~
[[ $(cat /etc/passwd | grep "^root:" | rev | cut -d":" -f1 | cut -d"/" -f1| rev) == "zsh" ]]
~~~

## S18

**description:** Change shell system wide to ZSH

**Command:** 
~~~
export ZSHLOCATION=$(grep /zsh$ /etc/shells | tail -1), sed -i "s|^SHELL=.*|SHELL=${ZSHLOCATION}|" /etc/default/useradd, sed -i "s|^DSHELL=.*|DSHELL=${ZSHLOCATION}|" /etc/adduser.conf, apt_install_wrapper apt-get -y install armbian-zsh zsh-common zsh tmux, update_skel, awk -F'[/:]' '{if ($3 >= 1000 && $3 != 65534 || $3 == 0) print $1}' /etc/passwd | xargs -L1 chsh -s $(grep /zsh$ /etc/shells | tail -1)
~~~

**Author:** https://github.com/igorpecovnik

**Status:** Preview

**Condition:**
~~~
[[ $(cat /etc/passwd | grep "^root:" | rev | cut -d":" -f1 | cut -d"/" -f1| rev) == "bash" ]]
~~~

## S19

**description:** Switch to rolling release

**about:** 
This will switch to rolling releases

would you like to continue?

**Command:** 
~~~
set_rolling
~~~

**Author:** Igor Pecovnik

**Status:** Preview

**Condition:**
~~~
grep -q 'apt.armbian.com' /etc/apt/sources.list.d/armbian.list && [[ -z "$(apt-mark showhold)" ]]
~~~

## S20

**description:** Switch to stable release

**about:** 
This will switch to stable releases

would you like to continue?

**Command:** 
~~~
set_stable
~~~

**Author:** Igor Pecovnik

**Status:** Preview

**Condition:**
~~~
grep -q 'beta.armbian.com' /etc/apt/sources.list.d/armbian.list && [[ -z "$(apt-mark showhold)" ]]
~~~

## S21

**description:** Enable read only filesystem

**about:** 
This will enable Armbian read-only filesystem. Reboot is mandatory?


**Command:** 
~~~
manage_overlayfs enable
~~~

**Author:** Igor Pecovnik

**Status:** Preview

**Condition:**
~~~
modinfo overlay > /dev/null 2>&1 && [[ -z $(findmnt -k /media/root-ro | tail -1) ]] && [[ "${DISTRO}"=Ubuntu ]]
~~~

## S22

**description:** Disable read only filesystem

**about:** 
This will disable Armbian read-only filesystem. Reboot is mandatory?


**Command:** 
~~~
manage_overlayfs disable
~~~

**Author:** Igor Pecovnik

**Status:** Preview

**Condition:**
~~~
command -v overlayroot-chroot > /dev/null 2>&1 && findmnt -k /media/root-ro | tail -1 | grep -w /media/root-ro > /dev/null 2>&1
~~~

## S23

**description:** Adjust welcome screen (motd)

**Command:** 
~~~
adjust_motd
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
[ -f /etc/default/armbian-motd ]
~~~

## S24

**description:** Install alternative kernels

**about:** 
Switching between kernels might change functionality of your device. 

It might fail to boot!

**Command:** 
~~~
switch_kernels
~~~

**Author:** Igor Pecovnik

**Status:** Preview

**Condition:**
~~~

~~~

## S25

**description:** Distribution upgrades

**Condition:**
~~~
[ -f /etc/armbian-distribution-status ] && release_upgrade rolling verify || release_upgrade stable verify
~~~

### S26

**description:** Upgrade to latest stable / LTS

**about:** 
Release upgrade is irriversible operation which upgrades all packages. 

Resoulted upgrade might break your build beyond repair!

**Command:** 
~~~
release_upgrade stable
~~~

**Author:** Igor Pecovnik

**Status:** Active

**Condition:**
~~~
[ -f /etc/armbian-distribution-status ] && release_upgrade stable verify
~~~

### S27

**description:** Upgrade to rolling unstable

**about:** 
Release upgrade is irriversible operation which upgrades all packages. 

Resoulted upgrade might break your build beyond repair!

**Command:** 
~~~
release_upgrade rolling
~~~

**Author:** Igor Pecovnik

**Status:** Active

**Condition:**
~~~
[ -f /etc/armbian-distribution-status ] && release_upgrade rolling verify
~~~

## S28

**description:** Manage device tree overlays

**Command:** 
~~~
manage_dtoverlays
~~~

**Author:** Gunjan Gupta

**Status:** Active

**Condition:**
~~~
[ -n $OVERLAY_DIR ] && [ -n $BOOT_SOC ]
~~~

