=== "Configuration"

    Database access configuration is done at first install:

    - create root password
    - create database
    - create normal user
    - create password for normal user

    - Database host: `<your.IP>`

=== "Directories"

    - Install directory: `/armbian/mysql`
    - Data volume mounted to: `/armbian/mysql/data`

=== "View logs"

    ```sh
    docker logs -f mysql
    ```
