=== "Access to the service"

    The proxy listens on port **3142**:

    - URL: `http://<your.IP>:3142`
    - Hit-rate report: `http://<your.IP>:3142/acng-report.html`

=== "Client configuration"

    On each apt host on the LAN:

    ```sh
    echo 'Acquire::http::Proxy "http://<your.IP>:3142";' \
      | sudo tee /etc/apt/apt.conf.d/00aptproxy
    ```

=== "Directories"

    - Cache: `/armbian/apt-cacher-ng/cache/`

=== "View logs"

    ```sh
    docker logs -f apt-cacher-ng
    ```
