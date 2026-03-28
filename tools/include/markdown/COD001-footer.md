=== "Access to the web interface"

    The web interface is accessible via port **8443**:

    - URL: `https://<your.IP>:8443`
    - Default Login: No password required by default (see optional variables below)

    **Note**: Code-server uses HTTPS with a self-signed certificate by default. Your browser may show a security warning - this is normal for self-signed certificates.

=== "Directories"

    - Install directory: `/armbian/code-server`
    - Configuration directory: `/armbian/code-server/config`

=== "Optional Environment Variables"

    You can customize code-server by passing additional environment variables:

    - **PASSWORD** - Set a simple password for web UI access (not recommended for production)
    - **HASHED_PASSWORD** - Set a hashed password for enhanced security (recommended)
    - **SUDO_PASSWORD** - Set a password for sudo access within code-server terminal
    - **PROXY_DOMAIN** - Configure proxy domain for reverse proxy setups
    - **DEFAULT_WORKSPACE** - Set the default workspace directory
    - **PWA_APPNAME** - Customize the PWA (Progressive Web App) name

    To add these variables, edit the container and restart:

    ```sh
    docker stop code-server
    docker rm code-server
    # Then reinstall with modified environment variables
    ```

=== "View logs"

    ```sh
    docker logs -f code-server
    ```

=== "Password hashing"

    To generate a hashed password for the HASHED_PASSWORD variable:

    ```sh
    docker run -it --rm lscr.io/linuxserver/code-server:latest hash_password
    ```

=== "Troubleshooting"

    - **Browser shows certificate warning**: Accept the security warning to proceed (self-signed certificate)
    - **Cannot access web UI**: Check if port 8443 is open in your firewall
    - **Extensions not installing**: Check internet connectivity from the container
    - **Slow performance**: Consider increasing Docker resource limits

=== "Official Documentation"

    For more advanced configuration and usage, visit:
    - [Code-server GitHub](https://github.com/coder/code-server)
    - [LinuxServer.io Code-server](https://github.com/linuxserver/docker-code-server)
