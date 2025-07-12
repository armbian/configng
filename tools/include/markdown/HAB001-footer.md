=== "Access to the web interface"

    The web interface is accessible via port **8080**:

    - URL: `https://<your.IP>:8080`
    - Username/Password: Are set at first web interface login

=== "Directories"

    - Install directory: `/usr/share/openhab`
    - Site configuration directory: `/etc/openhab`
    - Config file: `/etc/default/openhab`
    - Data directory: `/var/lib/openhab`

    See also [openHAB file locations](https://www.openhab.org/docs/installation/linux.html#file-locations).

=== "View logs"

    ```sh
    journalctl -u openhab
    ```
