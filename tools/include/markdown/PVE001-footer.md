=== "Access to the web interface"

    The web interface is accessible via port **8006**:

    - URL: `https://<your.IP>:8006`
    - Username: `root` (your system root password)

    Official documentation: <https://pve.proxmox.com/pve-docs/>

=== "Runs on the Armbian kernel"

    This install intentionally omits the Proxmox kernel and runs on the board's
    Armbian kernel:

    - KVM virtual machines and LXC containers work normally.
    - **ZFS** is installed via DKMS (built against the Armbian kernel), so ZFS
      storage pools work; only ZFS-on-**root** (boot) is out of scope.

=== "Requirements"

    - Debian **13 (trixie)** on **amd64** or **arm64**.
    - The hostname must resolve to a non-loopback IP in `/etc/hosts`, e.g.:

        ```
        192.168.1.50   pve.local pve
        ```

=== "Directories"

    - Configuration: `/etc/pve`
    - Cluster data: `/var/lib/pve-cluster`
