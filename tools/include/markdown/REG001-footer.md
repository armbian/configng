=== "Armbian builds"

    ```sh
    ./compile.sh OCI_PROXY=<address>:5000 ...
    ```

=== "Directories"

    - Cache: `/armbian/registry-cache/data/`

=== "View logs"

    ```sh
    docker logs -f registry-cache
    ```
