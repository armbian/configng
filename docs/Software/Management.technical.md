- [Remote Management tools](#management)
  - [Install Cockpit web-based management tool](#m00)
  - [Purge Cockpit web-based management tool](#m01)
  - [Start Cockpit Service](#m02)
  - [Stop Cockpit Service](#m03)

# Management

**description:** Remote Management tools


## M00

**description:** Install Cockpit web-based management tool

**prompt:** 
This operation will install Cockpit.
cockpit cockpit-ws cockpit-system cockpit-storaged
Would you like to continue?

**Command:** 
~~~
see_current_apt update, apt_install_wrapper apt -y install cockpit cockpit-ws cockpit-system cockpit-storaged 
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed cockpit
~~~

## M01

**description:** Purge Cockpit web-based management tool

**prompt:** 
This operation will purge Cockpit.
Would you like to continue?

**Command:** 
~~~
apt_install_wrapper apt -y purge cockpit
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed cockpit
~~~

## M02

**description:** Start Cockpit Service

**Command:** 
~~~
sudo systemctl enable --now cockpit.socket | show_infobox 
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed cockpit && ! systemctl is-enabled cockpit.socket > /dev/null 2>&1
~~~

## M03

**description:** Stop Cockpit Service

**Command:** 
~~~
systemctl stop cockpit cockpit.socket, systemctl disable cockpit.socket | show_infobox 
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed cockpit && systemctl is-enabled cockpit.socket > /dev/null 2>&1
~~~

