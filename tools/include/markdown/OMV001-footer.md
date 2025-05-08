=== "Access to the web interface"

    The OpenMediaVault web interface is accessible via the default HTTP port:

    - URL: `http://<your.IP>:80`
    - Username/Password: admin / openmediavault (change after first login)

=== "Directories"

    - Default config directory: `/etc/openmediavault/`
    - Shared folders base path: `/srv/dev-disk-by-.../`
    - Plugin data directories may vary by service (e.g., Docker, SMB, etc.)

=== "Usage"

    - Use the web interface to configure storage, users, services, and plugins
    - Create shared folders and enable SMB/NFS to access files over the network
    - Monitor system status, performance, and logs from the dashboard

=== "Plugins and Add-ons"

    OpenMediaVault supports a wide range of community plugins:

    - Docker support via `openmediavault-compose` or `omv-extras`
    - Media servers (e.g., Plex, Jellyfin)
    - Backup tools (e.g., rsync, USB backup)
    - Cloud sync (e.g., Rclone)

    Install plugins through the web interface after enabling OMV-Extras.

=== "View logs"

    ```sh
    journalctl -u openmediavault-engined
    tail -f /var/log/syslog
    ```
