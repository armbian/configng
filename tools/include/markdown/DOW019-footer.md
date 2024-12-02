=== "Access to the web interface"

    The web interface is accessible via port **6767**:

    - URL: `https://<your.IP>:6767`
    - Username/Password: admin / generate at first web interface login

=== "Directories"

    - Install directory: `/armbian/bazarr`
    - Site configuration directory: `/armbian/bazarr/config`
    - Download directory: `/armbian/bazarr/movies` `/armbian/bazarr/tv`

=== "View logs"

    ```sh
    docker logs -f bazarr
    ```
