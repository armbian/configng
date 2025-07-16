=== "Access to the web interface"

    The web interface is accessible via port **2080**:

    - URL: `https://<your.IP>:2080`
    - Username/Password: Are set at first web interface login

=== "Directories"

    - Install directory: `/armbian/openhab`
    - Site configuration directory: `/armbian/openhab/conf`
    - Userdata directory: `/armbian/openhab/userdata`
    - Addons directory: `/armbian/openhab/addons`

    See also [openHAB file locations](https://www.openhab.org/docs/installation/linux.html#file-locations).

=== "View logs"

    ```sh
    docker logs -f openhab
    ```
