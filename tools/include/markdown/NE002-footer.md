=== "Wired device check"

    In order to configure your network devices, they need to be supported the kernel.

    To verify, use command:

    ```sh
    ip addr
    ```

    It is usually something like eth0, enp4s3 or lan.

=== "Wireless device check"

    In order to configure your wireless network devices, they need to be supported the kernel.

    To verify, use command:

    ```sh
    iw dev | awk '$1=="Interface"{print $2}'
    ```

    It is usually something like `wlan0`, `wlo1` or `wlx12334c47dec3`. If you get blank response, it means your WiFi device / dongle is not supported by the kernel.
