=== "Access to the server from internet"

    Remember to open/forward the port 51820 (UDP) through NAT on your router.
    
=== "Directories"

    - Install directory: `/armbian/wireguard`
    - Site configuration directory: `/armbian/wireguard/config`

=== "View logs"

    ```sh
    docker logs -f wireguard
    ```

# Install server and enable private network on a client

1. Install Wireguard server
2. It will asks you for peer keywords. It will make a profile for each peer
3. Download client to your PC, server or mobile phone. Scan OR code or copy credentials to the client.

Enjoy private network! Its that easy.

More informations:

<https://docs.linuxserver.io/images/docker-wireguard/>