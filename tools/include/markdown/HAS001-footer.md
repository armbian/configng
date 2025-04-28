=== "Access to the web interface"

    The web interface is accessible via port **8123**:

    - URL: `https://<your.IP>:8123`
    - Username/Password: Are set at first web interface login

=== "Directories"

    Home Assistant on Armbian runs supervised in a Docker container. This secures same functionality as stock HAOS.

    - Config directory: `/armbian/haos`

=== "Armbian advantages"

    |Functionality|HAOS|Armbian with HA|
    |:--|:--:|:--:|
    |Automations|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|
    |Dashboards|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|
    |Integrations|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|
    |Add-ons|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|
    |One-click updates|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|
    |Backups|:heavy_check_mark:|:heavy_check_mark:|:heavy_check_mark:|
    |General purpose server|:x:|:white_check_mark:|
    |Running on exotic hardware|:x:|:white_check_mark:|
