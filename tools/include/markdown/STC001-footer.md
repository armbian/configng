=== "Access to the web interface"

    - Username/Password: There is none, but it is highly suggested setting a password for this container. To do this go to Actions -> Settings -> set user/password for the webUI.

=== "Directories"

    - Install directory: `/armbian/syncthing`
    - Site configuration directory: `/armbian/syncthing/config`
    - Data directory: `/armbian/syncthing/data1` `/armbian/syncthing/data2`

=== "View logs"

    ```sh
    docker logs -f syncthing
    ```
