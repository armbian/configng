- [Containerlization and Virtual Machines](#containers)
  - [Install Docker Minimal](#sw25)
  - [Install Docker Engine](#sw26)
  - [Remove Docker](#sw27)
  - [Purge all Docker images, containers, and volumes](#sw28)

# Containers

**description:** Containerlization and Virtual Machines


## SW25

**description:** Install Docker Minimal

**prompt:** 
This operation will install Docker Minimal.
Would you like to continue?

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

**prompt:** 
This operation will install Docker Engine.
Would you like to continue?

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

**prompt:** 
This operation will purge Docker.
Would you like to continue?

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

**prompt:** 
This operation will delete all Docker images, containers, and volumes.
Would you like to continue?

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

