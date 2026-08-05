=== "Access to the web interface"

    The web interface is accessible via port **8006**:

    - URL: `https://<your.IP>:8006`
    - Username: `root` (your system root password)

    Official documentation: <https://pve.proxmox.com/pve-docs/>

=== "Runs on the Armbian kernel"

    This install intentionally omits the Proxmox kernel and runs on the board's
    Armbian kernel:

    - KVM virtual machines and LXC containers work provided the running kernel
      offers the needed support (KVM / `/dev/kvm` and container
      cgroups/namespaces) — which the Armbian kernels for these arches normally do.
    - This module **installs ZFS** for you (via DKMS, built against the Armbian
      kernel), so ZFS storage pools work out of the box; only ZFS-on-**root**
      (boot) is out of scope.

=== "Requirements"

    - **Armbian Trixie** (Debian 13) on **amd64** or **arm64** (enforced by the installer).
    - **Recommended:** the hostname should resolve to a non-loopback IP in
      `/etc/hosts`, e.g.:

        ```
        192.168.1.50   pve.local pve
        ```

        If it resolves only to a loopback address (`127.x` or IPv6 `::1`), the
        installer warns and lets you continue, but the web UI and clustering
        may not work until you fix `/etc/hosts`.

=== "Directories"

    - Configuration: `/etc/pve`
    - Cluster data: `/var/lib/pve-cluster`
