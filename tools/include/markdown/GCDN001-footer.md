=== "Access to the service"

    The proxy listens on port **8000**:

    - URL: `http://<your.IP>:8000`

=== "Client configuration"

    On each git host on the LAN, redirect GitHub through the proxy:

    ```sh
    git config --global \
      url."http://<your.IP>:8000/".insteadOf https://github.com/
    ```

    Then clone normally — fetches are served from the local cache:

    ```sh
    git clone https://github.com/<owner>/<repo>.git
    ```

=== "Directories"

    - Cache: `/armbian/git_cdn/cache/`

=== "View logs"

    ```sh
    docker logs -f git_cdn
    ```
