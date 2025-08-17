=== "Server"

    1. Launch `armbian-config --cmd WRG001`.

    2. When prompted, enter a comma-separated list of peer names (e.g., laptop,phone,router).

    3. Peer configuration files will be created in

        ```
        /armbian/wireguard/config/wg_confs/peer_laptop.conf
        ```
    4. Scan the QR code (for mobile) or transfer .conf to your client system.

    5. Connect the client using the configuration.

=== "Client"

    1. Launch `armbian-config --cmd WRG002`.

    2. You will be asked to edit or paste a valid WireGuard configuration.

    3. Provide the client configuration in this format:

    ```sh
    [Interface]
    Address = 10.13.13.2/32
    PrivateKey = <your-private-key>
    DNS = 1.1.1.1

    [Peer]
    PublicKey = <server-public-key>
    Endpoint = your.server.com:51820
    AllowedIPs = 0.0.0.0/0
    PersistentKeepalive = 25
    ```

    4. The configuration will be saved to:

        ```
        /armbian/wireguard/config/wg_confs/client.conf
        ```

    5. When prompted, enter the local LAN subnets you wish to route via VPN (e.g., `10.0.10.0/24,192.168.0.0/16`).

    6. The VPN container will be started and routing rules will be generated accordingly.

    7. Routing will be restored automatically on boot via systemd service.

=== "Access to the server from internet"

    Remember to open/forward the port 51820 (UDP) through NAT on your router.
    
=== "Directories"

    - Install directory: `/armbian/wireguard`
    - Site configuration directory: `/armbian/wireguard/config`

=== "View logs"

    ```sh
    docker logs -f wireguard
    ```