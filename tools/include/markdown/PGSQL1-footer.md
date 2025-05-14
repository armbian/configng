=== "Access to the database"

    PostgreSQL is accessible via port **5432**:

    - Host: `postgresql://<your.IP>:5432`
    - Default user: `armbian`
    - Default password: `armbian`
    - Default database: `armbian`

=== "Directories"

    - Data directory: `/armbian/postgres/data`

=== "View logs"

    ```sh
    docker logs -f postgres
    ```
