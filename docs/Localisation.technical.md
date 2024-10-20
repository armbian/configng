- [Localisation](#localisation): Localisation
  - [L00](#l00): Change Global timezone (WIP)
  - [L01](#l01): Change Locales reconfigure the language and character set
  - [L02](#l02): Change Keyboard layout
  - [L03](#l03): Change APT mirrors
  - [L04](#l04): Change System Hostname

# Localisation

**Description:** Localisation


## L00

**Description:** Change Global timezone (WIP)

**Command:** 
~~~
dpkg-reconfigure tzdata
~~~

**Author:** 

**Status:** Preview


## L01

**Description:** Change Locales reconfigure the language and character set

**Command:** 
~~~
dpkg-reconfigure locales, source /etc/default/locale ; sed -i "s/^LANGUAGE=.*/LANGUAGE=$LANG/" /etc/default/locale, export LANGUAGE=$LANG
~~~

**Author:** 

**Status:** Preview


## L02

**Description:** Change Keyboard layout

**Command:** 
~~~
dpkg-reconfigure keyboard-configuration ; setupcon , update-initramfs -u
~~~

**Author:** 

**Status:** Preview


## L03

**Description:** Change APT mirrors

**Prompt:** 
This will change the APT mirrors
Would you like to continue?

**Command:** 
~~~
get_user_continue "This is only a frontend test" process_input
~~~

**Author:** 

**Status:** Disabled


## L04

**Description:** Change System Hostname

**Command:** 
~~~
change_system_hostname
~~~

**Author:** 

**Status:** Preview


