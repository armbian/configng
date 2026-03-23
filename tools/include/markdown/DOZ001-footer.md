=== "Access to the web interface"

    The web interface is accessible via port **8888**:

    - URL: `http://<your.IP>:8888`

=== "View logs"

    View real-time logs from the Dozzle container:

    ```sh
    docker logs -f dozzle
    ```

=== "Security considerations"

    Dozzle does not include built-in authentication. For production use, consider:

    - Running behind a reverse proxy with authentication (e.g., SWAG, Nginx)
    - Using firewall rules to restrict access to trusted networks
    - Configuring VPN access for remote log viewing

=== "Troubleshooting"

    If Dozzle cannot display logs from certain containers:

    - Ensure the Docker socket is properly mounted
    - Check that the container has logs available: `docker logs <container_name>`
    - Verify Dozzle container is running: `docker ps | grep dozzle`

