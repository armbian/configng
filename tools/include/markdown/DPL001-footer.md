=== "Access to the web interface"

    The web interface is accessible via port **8200**:

    - URL: `http://<your.IP>:8200`

=== "Directories"

    - Install directory: `/armbian/duplicati`
    - Configuration directory: `/armbian/duplicati/config`
    - Backup target directory: `/armbian/duplicati/backups`

=== "View logs"

    ```sh
    docker logs -f duplicati
    ```
