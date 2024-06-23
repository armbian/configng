
# Menu list.
armbian-config jobs list.

### S01

Enable Armbina kernal upgrades

Jobs:

~~~
set_safe_boot unhold
~~~

### S02

Disable Armbina kernal upgrades

Jobs:

~~~
set_safe_boot freeze
~~~

### S03

Edit the boot enviroment (WIP)

Jobs:

~~~
get_user_continue "This will open /boot/armbianEnv.txt file to edit
CTRL+S to save
CTLR+X to exit
would you like to continue?" process_input
nano /boot/armbianEnv.txt
~~~

### S04

Install Linux headers

Jobs:

~~~
Headers_install
~~~

### S05

Remove Linux headers

Jobs:

~~~
Headers_remove
~~~

### BT0

Install Bluetooth support

Jobs:

~~~
see_current_apt 
debconf-apt-progress -- apt-get -y install bluetooth bluez bluez-tools
check_if_installed xserver-xorg && debconf-apt-progress -- apt-get -y --no-install-recommends install pulseaudio-module-bluetooth blueman
~~~

### BT1

Remove Bluetooth support

Jobs:

~~~
see_current_apt 
debconf-apt-progress -- apt-get -y remove bluetooth bluez bluez-tools
check_if_installed xserver-xorg && debconf-apt-progress -- apt-get -y remove pulseaudio-module-bluetooth blueman
debconf-apt-progress -- apt -y -qq autoremove
~~~

### BT3

Bluetooth Discover

Jobs:

~~~
get_user_continue "Verify that your Bluetooth device is discoverable!" process_input ; connect_bt_interface
~~~

### IR0

Install Infrared support

Jobs:

~~~
see_current_apt; debconf-apt-progress -- apt-get -y --no-install-recommends install lirc
~~~

### IR1

Uninstall Infrared support

Jobs:

~~~
see_current_apt; debconf-apt-progress -- apt-get -y --no-install-recommends install lirc
~~~

### N00

Manage wifi network connections

Jobs:

~~~
nmtui connect
~~~

### N01

Advanced Edit /etc/network/interface

Jobs:

~~~
get_user_continue "This will open interface file to edit
CTRL+S to save
CTLR+X to exit
would you like to continue?" process_input
nano /etc/network/interfaces
~~~

### N02

Disconect and forget all wifi connections (Advanced)

Jobs:

~~~
get_user_continue "Disconect and forget all wifi connections
Would you like to contiue?" process_input
LC_ALL=C nmcli --fields UUID,TIMESTAMP-REAL,TYPE con show | grep wifi |  awk '{print $1}' | while read line; \ 
do nmcli con delete uuid  $line; done > /dev/null
~~~

### N03

Toggle system IPv6/IPv4 internet protical

Jobs:

~~~
get_user_continue "This will toggle your internet protical
Would you like to contiue?" process_input
toggle_ipv6 | show_infobox
~~~

### N04

(WIP) Setup Hotspot/Access point

Jobs:

~~~
get_user_continue "This operation will install necessary software and add configuration files.
Do you wish to continue?" process_input
hotspot_setup
~~~

### L00

Change Globla timezone (WIP)

Jobs:

~~~
dpkg-reconfigure tzdata
~~~

### L01

Change Locales reconfigure the language and charitorset

Jobs:

~~~
dpkg-reconfigure locales
source /etc/default/locale ; sed -i "s/^LANGUAGE=.*/LANGUAGE=$LANG/" /etc/default/locale
export LANGUAGE=$LANG
~~~

### L02

Change Keyboard layout

Jobs:

~~~
dpkg-reconfigure keyboard-configuration ; setupcon 
~~~

### L03

Change APT mirrors

Jobs:

~~~
get_user_continue "This is only a frontend test" process_input
~~~

### I00

Update Application Repository

Jobs:

~~~
get_user_continue "This will update apt" process_input
debconf-apt-progress -- apt update
~~~

### I01

CLI System Monitor

Jobs:

~~~
armbianmonitor -m | show_infobox
~~~

### H00

About This systme. (WIP)

Jobs:

~~~
show_message <<< "This app is to help exicute prosedures to configure your system

Some option may not work on manualy modified sytemes"
~~~

### H02

List of Config function(WIP)

Jobs:

~~~
show_message <<< see_use
~~~

