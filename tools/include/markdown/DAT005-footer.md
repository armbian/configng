=== "Access to the web interface"

    The web interface is accessible via port **8071**:

    - URL: `https://<your.IP>:8071`
    - Server: IP from server you are connecting to. If you have installed MariaDB via this tool, then this is `<your.IP>`
    - Username: defined at SQL server install (MariaDb)
    - Password: defined at SQL server install (MariaDb)

=== "Directories"

    - Install directory: `/armbian/phpmyadmin`
    - Site configuration directory: `/armbian/phpmyadmin/config`

=== "View logs"

    ```sh
    docker logs -f phpmyadmin
    ```
