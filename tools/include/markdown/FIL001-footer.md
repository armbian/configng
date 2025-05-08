=== "Access to the web interface"

    The web interface is accessible via port **8095**:

    - URL: `http://<your.IP>:8095`
    - Username/Password: admin / admin

=== "Directories"

    - Install directory: `/armbian/filebrowser`
    - Root directory: `/armbian/filebrowser/srv`
    - Database directory: `/armbian/filebrowser/database`
    - Configuration file: `/armbian/filebrowser/filebrowser.json`
    - Branding directory: `/armbian/filebrowser/branding`

=== "View logs"

    ```sh
    docker logs -f filebrowser
    ```
