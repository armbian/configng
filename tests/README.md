# Unit tests

If function testcase returns 0, test is succesful. Put the code there.

- name of the the file is function ID.conf
- ENABLED=false|true
- RELEASE="bookworm:jammy:noble" run on specific or leave empty to run on all

Example:

```
ENABLED=true
RELEASE="bookworm:noble"

function testcase {
        ./bin/armbian-config --api module_cockpit install
        [ -f /usr/bin/cockpit-bridge ]
}
```
