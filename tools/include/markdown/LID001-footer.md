=== "Access to the web interface"

    The web interface is accessible via port **8686**:

    - URL: `https://<your.IP>:8686`
    - Username/Password: admin / generate at first web interface login

=== "Directories"

    - Install directory: `/armbian/lidarr`
    - Site configuration directory: `/armbian/lidarr/config`
    - Download directory: `/armbian/lidarr/downloads` `/armbian/lidarr/music`

=== "View logs"

    ```sh
    docker logs -f lidarr
    ```
