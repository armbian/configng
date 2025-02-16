# Unit tests

If the function `testcase()` returns 0, the test is succesful. Put the code there.

- name of the the file is function ID.conf
- ENABLED=false|true
- RELEASE="bookworm:jammy:noble" run on specific or leave empty to run on all

Example:

```sh
ENABLED=true
RELEASE="bookworm:noble"

testcase() {
    ./bin/armbian-config --api module_cockpit install
    [ -f /usr/bin/cockpit-bridge ]
}
```

If you have multiple test conditions inside `testcase()` and you want the test
to exit on the first failed statement, you can use the following technique:

```sh
testcase() {(
    set -e
      ./bin/armbian-config --api pkg_install   neovim
      ./bin/armbian-config --api pkg_installed neovim
      ./bin/armbian-config --api pkg_remove    neovim
    ! ./bin/armbian-config --api pkg_installed neovim
)}
```

Note the additional pair of `()` and the `set -e` command inside function body.
These will cause test conditions to run inside a subshell with the -e option
enabled (exit immediately if a pipeline returns non-zero status).
