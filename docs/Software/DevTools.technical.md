- [Development](#devtools)
  - [Install tools for cloning and managing repositories (git)](#sw17)
  - [Remove tools for cloning and managing repositories (git)](#sw18)

# DevTools

**description:** Development


## SW17

**description:** Install tools for cloning and managing repositories (git)

**Command:** 
~~~
get_user_continue "This operation will install git.

Do you wish to continue?" process_input, debconf-apt-progress -- apt-get -y install git
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
! check_if_installed git
~~~

## SW18

**description:** Remove tools for cloning and managing repositories (git)

**Command:** 
~~~
get_user_continue "This operation will remove git.

Do you wish to continue?" process_input, debconf-apt-progress -- apt-get -y purge git
~~~

**Author:** 

**Status:** Preview

**Condition:**
~~~
check_if_installed git
~~~

