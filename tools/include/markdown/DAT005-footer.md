=== "Access to the web interface"

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
