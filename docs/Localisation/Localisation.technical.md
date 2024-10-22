- [Localisation](#localisation)
  - [Change Global timezone (WIP)](#l00)
  - [Change Locales reconfigure the language and character set](#l01)
  - [Change Keyboard layout](#l02)
  - [Change APT mirrors](#l03)
  - [Change System Hostname](#l04)

# Localisation

**description:** Localisation


## L00

**description:** Change Global timezone (WIP)

**Command:** 
~~~
dpkg-reconfigure tzdata
~~~

**Author:** 

**Status:** Preview


## L01

**description:** Change Locales reconfigure the language and character set

**Command:** 
~~~
dpkg-reconfigure locales, source /etc/default/locale ; sed -i "s/^LANGUAGE=.*/LANGUAGE=$LANG/" /etc/default/locale, export LANGUAGE=$LANG
~~~

**Author:** 

**Status:** Preview


## L02

**description:** Change Keyboard layout

**Command:** 
~~~
dpkg-reconfigure keyboard-configuration ; setupcon , update-initramfs -u
~~~

**Author:** 

**Status:** Preview


## L03

**description:** Change APT mirrors

**about:** 
This will change the APT mirrors

**Command:** 
~~~
get_user_continue "This is only a frontend test" process_input
~~~

**Author:** 

**Status:** Disabled


## L04

**description:** Change System Hostname

**Command:** 
~~~
change_system_hostname
~~~

**Author:** 

**Status:** Preview


