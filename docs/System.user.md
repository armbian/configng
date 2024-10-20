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
--cmd S01
~~~

**Author:** 

**Status:** Preview


## S02

**Description:** Disable Armbian kernel upgrades

**Prompt:** 
Disable Armbian kernel/firmware upgrades
Would you like to continue?

**Command:** 
~~~
--cmd S02
~~~

**Author:** 

**Status:** Preview


## S03

**Description:** Edit the boot environment

**Prompt:** 
This will open /boot/armbianEnv.txt file to edit
CTRL+S to save
CTLR+X to exit
would you like to continue?

**Command:** 
~~~
--cmd S03
~~~

**Author:** 

**Status:** Preview


## S04

**Description:** Install Linux headers

**Command:** 
~~~
--cmd S04
~~~

**Author:** https://github.com/Tearran

**Status:** Preview


## S05

**Description:** Remove Linux headers

**Command:** 
~~~
--cmd S05
~~~

**Author:** https://github.com/Tearran

**Status:** Preview


## S06

**Description:** Install to internal storage

**Command:** 
~~~
--cmd S06
~~~

**Author:** https://github.com/igorpecovnik

**Status:** Preview


## S07.1

**Description:** Manage SSH login options


### S07

**Description:** Disable root login

**Command:** 
~~~
--cmd S07
~~~

**Author:** 

**Status:** Preview


### S08

**Description:** Enable root login

**Command:** 
~~~
--cmd S08
~~~

**Author:** 

**Status:** Preview


### S09

**Description:** Disable password login

**Command:** 
~~~
--cmd S09
~~~

**Author:** 

**Status:** Preview


### S10

**Description:** Enable password login

**Command:** 
~~~
--cmd S10
~~~

**Author:** 

**Status:** Preview


### S11

**Description:** Disable Public key authentication login

**Command:** 
~~~
--cmd S11
~~~

**Author:** 

**Status:** Preview


### S12

**Description:** Enable Public key authentication login

**Command:** 
~~~
--cmd S12
~~~

**Author:** 

**Status:** Preview


### S13

**Description:** Disable OTP authentication

**Command:** 
~~~
--cmd S13
~~~

**Author:** 

**Status:** Preview


### S14

**Description:** Enable OTP authentication

**Command:** 
~~~
--cmd S14
~~~

**Author:** 

**Status:** Preview


### S15

**Description:** Generate new OTP authentication QR code

**Command:** 
~~~
--cmd S15
~~~

**Author:** 

**Status:** Preview


### S16

**Description:** Show OTP authentication QR code

**Command:** 
~~~
--cmd S16
~~~

**Author:** Igor Pecovnik

**Status:** Preview


### S30

**Description:** Disable last login banner

**Command:** 
~~~
--cmd S30
~~~

**Author:** 

**Status:** Preview


### S31

**Description:** Enable last login banner

**Command:** 
~~~
--cmd S31
~~~

**Author:** 

**Status:** Preview


## S17

**Description:** Change shell system wide to BASH

**Command:** 
~~~
--cmd S17
~~~

**Author:** https://github.com/igorpecovnik

**Status:** Preview


## S18

**Description:** Change shell system wide to ZSH

**Command:** 
~~~
--cmd S18
~~~

**Author:** https://github.com/igorpecovnik

**Status:** Preview


## S19

**Description:** Switch to rolling release

**Prompt:** 
This will switch to rolling releases

would you like to continue?

**Command:** 
~~~
--cmd S19
~~~

**Author:** Igor Pecovnik

**Status:** Preview


## S20

**Description:** Switch to stable release

**Prompt:** 
This will switch to stable releases

would you like to continue?

**Command:** 
~~~
--cmd S20
~~~

**Author:** Igor Pecovnik

**Status:** Preview


## S21

**Description:** Enable read only filesystem

**Prompt:** 
This will enable Armbian read-only filesystem. Reboot is mandatory?

Would you like to continue?

**Command:** 
~~~
--cmd S21
~~~

**Author:** Igor Pecovnik

**Status:** Preview


## S22

**Description:** Disable read only filesystem

**Prompt:** 
This will disable Armbian read-only filesystem. Reboot is mandatory?

Would you like to continue?

**Command:** 
~~~
--cmd S22
~~~

**Author:** Igor Pecovnik

**Status:** Preview


## S23

**Description:** Adjust welcome screen (motd)

**Command:** 
~~~
--cmd S23
~~~

**Author:** 

**Status:** Preview


## S24

**Description:** Install alternative kernels

**Prompt:** 
Switching between kernels might change functionality of your device. 

It might fail to boot!

**Command:** 
~~~
--cmd S24
~~~

**Author:** Igor Pecovnik

**Status:** Preview


## S25

**Description:** Distribution upgrades


### S26

**Description:** Upgrade to latest stable / LTS

**Prompt:** 
Release upgrade is irriversible operation which upgrades all packages. 

Resoulted upgrade might break your build beyond repair!

**Command:** 
~~~
--cmd S26
~~~

**Author:** Igor Pecovnik

**Status:** Active


### S27

**Description:** Upgrade to rolling unstable

**Prompt:** 
Release upgrade is irriversible operation which upgrades all packages. 

Resoulted upgrade might break your build beyond repair!

**Command:** 
~~~
--cmd S27
~~~

**Author:** Igor Pecovnik

**Status:** Active


## S28

**Description:** Manage device tree overlays

**Command:** 
~~~
--cmd S28
~~~

**Author:** Gunjan Gupta

**Status:** Active


