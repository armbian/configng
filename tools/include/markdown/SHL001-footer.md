=== "Short domain"

    The install asks for the domain of the short links, for example `go.example.com`.

    - A domain without a port uses HTTPS. Put a reverse proxy with a certificate in front of port **8085**, for example [SWAG](https://docs.armbian.com/software/swag/).
    - Keep the default `<your.IP>:8085` to use Shlink on the local network only.
    - For an unattended install, set the domain in the environment:

    ```sh
    sudo SHLINK_DOMAIN=go.example.com armbian-config --api module_shlink install
    ```

=== "API key"

    The install creates an API key. Read it from the settings file:

    ```sh
    sudo grep INITIAL_API_KEY /armbian/shlink/shlink.env
    ```

    Create a short link:

    ```sh
    curl -X POST http://<your.IP>:8085/rest/v3/short-urls \
      -H "X-Api-Key: <key>" -H "Content-Type: application/json" \
      -d '{"longUrl": "https://docs.armbian.com/", "customSlug": "docs"}'
    ```

=== "Command line"

    ```sh
    docker exec -it shlink shlink short-url:create https://docs.armbian.com/
    docker exec -it shlink shlink short-url:list
    ```

=== "Directories"

    - Settings and API key: `/armbian/shlink/shlink.env`
    - Data: `/armbian/shlink/data/`

=== "View logs"

    ```sh
    docker logs -f shlink
    ```
