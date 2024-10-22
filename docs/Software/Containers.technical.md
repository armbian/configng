- [Containerlization and Virtual Machines](#containers)
  - [Install Docker Minimal](#sw25)
  - [Install Docker Engine](#sw26)
  - [Remove Docker](#sw27)
  - [Purge all Docker images, containers, and volumes](#sw28)

# Containers

**description:** Containerlization and Virtual Machines


## SW25

**description:** Install Docker Minimal

**about:** 
This operation will install Docker Minimal.

**Command:** 
~~~
install_docker
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed docker-ce
~~~

## SW26

**description:** Install Docker Engine

**about:** 
This operation will install Docker Engine.

**Command:** 
~~~
install_docker engine
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed docker-compose-plugin
~~~

## SW27

**description:** Remove Docker

**about:** 
This operation will purge Docker.

**Command:** 
~~~
apt_install_wrapper apt -y purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed docker-ce
~~~

## SW28

**description:** Purge all Docker images, containers, and volumes

**about:** 
This operation will delete all Docker images, containers, and volumes.

**Command:** 
~~~
rm -rf /var/lib/docker, rm -rf /var/lib/containerd
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed docker-ce && [ -d /var/lib/docker ]
~~~

