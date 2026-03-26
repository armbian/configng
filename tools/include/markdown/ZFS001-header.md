ZFS is an advanced, high-performance file system and volume manager designed for data integrity, scalability, and ease of use. It offers features like copy-on-write snapshots, native compression, data deduplication, automatic repair, and efficient storage pooling. Originally developed by Sun Microsystems, ZFS is ideal for handling large amounts of data reliably with minimal maintenance.

When enabling ZFS support, Armbian checks if the running kernel can support ZFS, installs matching kernel headers if necessary, and builds the ZFS DKMS (Dynamic Kernel Module Support) module automatically.

=== "ARC Cache Tuning"

    The **ARC (Adaptive Replacement Cache)** is ZFS's intelligent caching system.

    **Recommended Settings:**
    
    - **ARC Min:** 1/8 of RAM (minimum cache size)
    - **ARC Max:** 1/2 of RAM (maximum cache size)

    For memory-constrained ARM devices (1-2 GB RAM):
    
    - Consider limiting ARC to 256-512 MB to leave memory for applications
    - ARC Max = 0 means "use all available RAM" (may not be ideal for small systems)

    **Impact:**
    
    - Higher ARC = better read performance for frequently accessed data
    - Too high ARC can cause system swapping and degraded performance

=== "Dirty Data Tuning"

    **Dirty data** is modified data waiting to be written to disk.

    **Recommended Setting:**
    
    - **4% of RAM** (or 4% of ARC size, whichever is smaller)

    **Impact:**
    
    - Higher values = better write performance, more data loss risk on power failure
    - Lower values = safer data, more frequent disk writes

=== "TXG Timeout Tuning"

    **TXG (Transaction Group)** controls how often ZFS writes changes to disk.

    **Recommended Setting:**
    
    - **5 seconds** (default)

    **Range:** 1-30 seconds

    **Impact:**
    
    - Lower (1-3s): Better data safety, more disk writes, lower performance
    - Higher (10-30s): Better performance, more data loss risk on power failure

=== "Compression"

    ZFS compression is transparent and can actually **improve performance** by reducing I/O.

    **Options:**
    
    - **lz4**: Fast, good compression (recommended for most)
    - **zstd**: Better compression ratio, slightly slower CPU usage
    - **gzip**: Maximum compression, slowest
    - **off**: Disable compression

    **Note:** Compression setting only affects **new** datasets. Existing datasets keep their compression setting.

=== "Applying Configuration"

    Configuration is saved to `/etc/modprobe.d/zfs.conf` and requires reloading the ZFS module:

    ```bash
    # Option 1: Reboot (simplest)
    reboot

    # Option 2: Reload module (requires exporting all ZFS pools)
    zpool export -a
    rmmod zfs
    modprobe zfs
    ```

=== "Reset to Defaults"

    The tuning interface includes a "Reset to Defaults" option that:

    - Removes custom configuration from `/etc/modprobe.d/zfs.conf`
    - Resets all parameters to ZFS defaults
    - Requires module reload to take effect

=== "Pool Import"

    ZFS pools can be imported when they are not currently mounted. This is useful when:
    - Moving pools between systems
    - Booting from a different system with ZFS pools present
    - Pools were exported and need to be re-imported

    **Import Options:**

    - **Scan:** Lists all available pools that can be imported
    - **Import with original mount points:** Pool datasets mount at their configured locations
    - **Import with alternate mount point:** Pool datasets mount under a custom root directory

    **Force Import:**

    The import function uses `-f` flag to force import, which handles:
    - HostID mismatches between systems
    - Pool state issues
    - Active pools on other systems (use with caution)

    **Alternate Mount Point:**

    When importing with an alternate root (`altroot`):
    - Datasets mount under the specified path (e.g., `/mnt/pool`)
    - Original mount point configuration is preserved
    - Useful for temporary access or recovery scenarios

    **Note:** Default behavior is to use the pool's original mount points for maximum compatibility.
