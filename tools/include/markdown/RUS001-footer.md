=== "Configure RustDesk Clients"

    To connect your RustDesk clients to your self-hosted server:

    1. Open the RustDesk client application on your device
    2. Click the three-dot menu (⋮) and select **Settings**
    3. Navigate to the **Network** tab
    4. Enter your server details:

    ```text
    ID Server: <your-server-IP>:21114
    Relay Server: <your-server-IP>:21117
    Key: (see server setup for key)
    ```

    5. Click **OK** to save the settings

    To find your server key, check the generated file on the server:

    ```sh
    cat /armbian/rustdesk/id_server.txt
    ```

=== "Port Information"

    The RustDesk Server module uses the following ports:

    - **21114** - hbbs (ID/Rendezvous server) - Main connection port
    - **21115** - hbbs (NAT traversal) - For NAT traversal assistance
    - **21116** - hbbs (WebSocket) - For WebSocket client connections
    - **21117** - hbbr (Relay server) - For relayed connections

    Ensure these ports are allowed through your firewall if clients connect from outside your local network.

=== "View Logs"

    View logs from the RustDesk server containers:

    ```sh
    # hbbs (ID/Rendezvous server) logs
    docker logs -f rustdesk-hbbs

    # hbbr (Relay server) logs
    docker logs -f rustdesk-hbbr
    ```

=== "Data Directory"

    - **Data directory:** `/armbian/rustdesk`

    This directory contains:
    - `id_ed25519` - Private key for the server
    - `id_ed25519.pub` - Public key for client verification
    - `id_server.txt` - Server key for client configuration

    **Important:** Back up this directory. If lost, clients will need to be reconfigured with new keys.

=== "Troubleshooting"

    If clients cannot connect to the server:

    - **Check firewall settings:** Ensure ports 21114-21117 are open on the server
    - **Verify containers are running:** `docker ps | grep rustdesk`
    - **Check server logs:** Look for errors in `docker logs rustdesk-hbbs` or `docker logs rustdesk-hbbr`
    - **Confirm network settings:** Verify clients have the correct IP address and ports for both ID and Relay servers
    - **Test direct connection:** Ensure clients can reach the server IP and ports using `telnet <server-ip> 21114`

    If relay connections don't work:

    - The hbbr container must be running on port 21117
    - The hbbs container is configured with `-r rustdesk-hbbr:21117` for relay fallback
    - Check that the Docker network `lsio` allows inter-container communication

    Regenerating server keys:

    ```sh
    # Stop containers
    docker stop rustdesk-hbbs rustdesk-hbbr

    # Remove old keys
    rm -f /armbian/rustdesk/id_ed25519*

    # Restart containers (keys will be regenerated)
    docker start rustdesk-hbbs rustdesk-hbbr
    ```

    **Note:** After regenerating keys, all clients must be updated with the new server key.

=== "Security Considerations"

    - **Firewall Protection:** Exposing RustDesk Server ports to the internet allows anyone to attempt connections. Use firewall rules to restrict access to trusted IPs.
    - **HTTPS/TLS:** Consider running RustDesk Server behind a reverse proxy with SSL/TLS for encrypted connections.
    - **VPN Access:** For maximum security, access your self-hosted server through a VPN rather than exposing ports directly.
    - **Key Backup:** The `/armbian/rustdesk` directory contains sensitive cryptographic keys. Back it up securely and never share the private key.

