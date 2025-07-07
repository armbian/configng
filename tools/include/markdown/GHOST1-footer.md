=== "Configuration"

    Initial setup includes:

    - automatic database schema setup on first run
    - admin account created via web interface
    - Default port: `9190`
    - Admin URL: `http://<your.IP>:9190/ghost` (or behind reverse proxy like SWAG)
    - Site: `http://<your.IP>:9190`

=== "Directories"

    - Install directory: `/armbian/ghost`

=== "View logs"

    ```sh
    docker logs -f ghost
    ```
