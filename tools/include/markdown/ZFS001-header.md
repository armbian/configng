ZFS is an advanced, high-performance file system and volume manager designed for data integrity, scalability, and ease of use. It offers features like copy-on-write snapshots, native compression, data deduplication, automatic repair, and efficient storage pooling. Originally developed by Sun Microsystems, ZFS is ideal for handling large amounts of data reliably with minimal maintenance.

When enabling ZFS support, Armbian checks if the running kernel can support ZFS, installs matching kernel headers if necessary, and builds the ZFS DKMS (Dynamic Kernel Module Support) module automatically.
