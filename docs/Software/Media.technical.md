- [Media Servers and Editors](#media)
  - [Install Plex Media server](#sw21)
  - [Remove Plex Media server](#sw22)
  - [Install Emby server](#sw23)
  - [Remove Emby server](#sw24)

# Media

**description:** Media Servers and Editors


## SW21

**description:** Install Plex Media server

**prompt:** 
This operation will install Plex Media server.
Would you like to continue?

**Command:** 
~~~
install_plexmediaserver
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed plexmediaserver
~~~

## SW22

**description:** Remove Plex Media server

**prompt:** 
This operation will purge Plex Media server.
Would you like to continue?

**Command:** 
~~~
apt_install_wrapper apt-get -y purge plexmediaserver, sed -i '/plexmediaserver.gpg/s/^/#/g' /etc/apt/sources.list.d/plexmediaserver.list
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed plexmediaserver
~~~

## SW23

**description:** Install Emby server

**prompt:** 
This operation will install Emby server.
Would you like to continue?

**Command:** 
~~~
install_embyserver
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed emby-server
~~~

## SW24

**description:** Remove Emby server

**prompt:** 
This operation will purge Emby server.
Would you like to continue?

**Command:** 
~~~
apt_install_wrapper apt -y purge emby-server
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed emby-server
~~~

