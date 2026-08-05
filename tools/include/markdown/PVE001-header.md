[Proxmox VE](https://www.proxmox.com/en/proxmox-virtual-environment) is a complete, open-source server virtualization platform for running **KVM virtual machines** and **LXC containers** from a single, integrated web interface. It combines the tooling for compute, storage and software-defined networking so you can manage a whole host — or a cluster of them — from your browser.

This module installs Proxmox VE 9 from the official *no-subscription* repository on **Debian 13 (trixie)**, on both **amd64 and arm64**, and — unlike the upstream guide — **keeps the running Armbian kernel** instead of pulling the Proxmox one.

*Key Features*

- **KVM virtual machines**: Full hardware-accelerated VMs via the board's KVM-enabled Armbian kernel.
- **LXC containers**: Lightweight, fast system containers alongside your VMs.
- **Web management**: Manage guests, storage, backups and networking from `https://<ip>:8006`.
- **ZFS storage**: Installs ZFS (via DKMS, built against the Armbian kernel) so you can create ZFS pools and datasets for VM/container storage.
- **Keeps your kernel**: Installs `pve-manager` (no kernel dependency) rather than the `proxmox-ve` meta, so your Armbian kernel and DTBs stay in place.
- **No subscription needed**: Uses the public `pve-no-subscription` repository.

---

Ideal for turning an Armbian board into a lightweight hypervisor without giving up the board's own kernel and hardware support.
