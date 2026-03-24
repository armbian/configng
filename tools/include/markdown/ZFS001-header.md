ZFS is an advanced, high-performance file system and volume manager designed for data integrity, scalability, and ease of use. It offers features like copy-on-write snapshots, native compression, data deduplication, automatic repair, and efficient storage pooling. Originally developed by Sun Microsystems, ZFS is ideal for handling large amounts of data reliably with minimal maintenance.

When enabling ZFS support, Armbian checks if the running kernel can support ZFS, installs matching kernel headers if necessary, and builds the ZFS DKMS (Dynamic Kernel Module Support) module automatically.

**Performance Tuning:**

Once ZFS is installed, the **Tune ZFS** option becomes available, allowing you to fine-tune critical performance parameters:

- **ARC Cache (Adaptive Replacement Cache)**: ZFS's intelligent caching system that stores frequently accessed data in RAM. The ARC can consume 50% or more of system memory by default, which may be excessive for memory-constrained devices.

- **Dirty Data Limits**: Controls how much modified data can accumulate before being written to disk. Higher values improve performance but increase risk of data loss on power failure.

- **TXG Timeout**: Transaction Group timeout determines how often ZFS writes changes to disk. Lower values increase data safety at the cost of performance.

- **Compression**: Transparent compression that can actually improve performance by reducing I/O. LZ4 is recommended for most workloads.

**Recommended Settings for ARM Devices:**

- **ARC Max**: 1/2 to 2/3 of RAM (on 1-2GB systems, consider 256-512MB)
- **ARC Min**: 1/8 of RAM
- **Dirty Data Max**: 4% of RAM or ARC size (whichever is smaller)
- **TXG Timeout**: 5 seconds (default)
- **Compression**: lz4 (recommended)

The tuning interface provides safe defaults based on your system's memory size and allows you to adjust parameters with immediate feedback. Changes are saved to `/etc/modprobe.d/zfs.conf` and persist across reboots.
