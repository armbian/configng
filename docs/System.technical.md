- [System](#system): System wide and admin settings
  - [S01](#s01): Enable Armbian kernel/firmware upgrades
  - [S02](#s02): Disable Armbian kernel upgrades
  - [S03](#s03): Edit the boot environment
  - [S04](#s04): Install Linux headers
  - [S05](#s05): Remove Linux headers
  - [S06](#s06): Install to internal storage
  - [S07.1](#s07.1): Manage SSH login options
    - [S07](#s07): Disable root login
    - [S08](#s08): Enable root login
    - [S09](#s09): Disable password login
    - [S10](#s10): Enable password login
    - [S11](#s11): Disable Public key authentication login
    - [S12](#s12): Enable Public key authentication login
    - [S13](#s13): Disable OTP authentication
    - [S14](#s14): Enable OTP authentication
    - [S15](#s15): Generate new OTP authentication QR code
    - [S16](#s16): Show OTP authentication QR code
    - [S30](#s30): Disable last login banner
    - [S31](#s31): Enable last login banner
  - [S17](#s17): Change shell system wide to BASH
  - [S18](#s18): Change shell system wide to ZSH
  - [S19](#s19): Switch to rolling release
  - [S20](#s20): Switch to stable release
  - [S21](#s21): Enable read only filesystem
  - [S22](#s22): Disable read only filesystem
  - [S23](#s23): Adjust welcome screen (motd)
  - [S24](#s24): Install alternative kernels
  - [S25](#s25): Distribution upgrades
    - [S26](#s26): Upgrade to latest stable / LTS
    - [S27](#s27): Upgrade to rolling unstable
  - [S28](#s28): Manage device tree overlays

# System

**Description:** System wide and admin settings


## S01

**Description:** Enable Armbian kernel/firmware upgrades

**Prompt:** 
This will enable Armbian kernel upgrades?
Would you like to continue?

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

**Description:** Disable Armbian kernel upgrades

**Prompt:** 
Disable Armbian kernel/firmware upgrades
Would you like to continue?

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

**Description:** Edit the boot environment

**Prompt:** 
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

**Description:** Install Linux headers

**Command:** 
~~~
Headers_install
~~~

**Author:** https://github.com/Tearran

**Status:** Preview

**Condition:**
~~~
 ! are_headers_installed
~~~

## S05

**Description:** Remove Linux headers

**Command:** 
~~~
Headers_remove
~~~

**Author:** https://github.com/Tearran

**Status:** Preview

**Condition:**
~~~
 are_headers_installed
~~~

## S06

**Description:** Install to internal storage

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

## S07.1

**Description:** Manage SSH login options


### S07

**Description:** Disable root login

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

**Description:** Enable root login

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

**Description:** Disable password login

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

**Description:** Enable password login

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

**Description:** Disable Public key authentication login

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

**Description:** Enable Public key authentication login

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

**Description:** Disable OTP authentication

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

**Description:** Enable OTP authentication

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

**Description:** Generate new OTP authentication QR code

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

**Description:** Show OTP authentication QR code

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

**Description:** Disable last login banner

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

**Description:** Enable last login banner

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

**Description:** Change shell system wide to BASH

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

**Description:** Change shell system wide to ZSH

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

**Description:** Switch to rolling release

**Prompt:** 
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

**Description:** Switch to stable release

**Prompt:** 
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

**Description:** Enable read only filesystem

**Prompt:** 
This will enable Armbian read-only filesystem. Reboot is mandatory?

Would you like to continue?

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

**Description:** Disable read only filesystem

**Prompt:** 
This will disable Armbian read-only filesystem. Reboot is mandatory?

Would you like to continue?

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

**Description:** Adjust welcome screen (motd)

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

**Description:** Install alternative kernels

**Prompt:** 
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

**Description:** Distribution upgrades

**Condition:**
~~~
 [ -f /etc/armbian-distribution-status ] && release_upgrade rolling verify || release_upgrade stable verify
~~~

### S26

**Description:** Upgrade to latest stable / LTS

**Prompt:** 
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

**Description:** Upgrade to rolling unstable

**Prompt:** 
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

**Description:** Manage device tree overlays

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

