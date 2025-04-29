=== "Access to the service"

    NetBox is accessible via HTTP on port **8000**:

    - URL: `http://<your.IP>:8000`
    - API root: `http://<your.IP>:8000/api/`

=== "Default credentials"

    - Username: `admin`
    - Password: *(set during setup)*
    - API token: *Generate in the UI or via Django shell*

=== "Directories"

    - Configuration: `/armbian/netbox/config/`
    - Scripts: `/armbian/netbox/scripts/`
    - Reports: `/armbian/netbox/reports/`

=== "View logs"

    ```sh
    docker logs -f netbox
    ```

=== "Manage the service"

    ```sh
    docker exec -it netbox bash
    ```
