## Performance Tuning

The ZFS module includes a comprehensive tuning interface accessible via **System → Storage → Tune ZFS** (or `armbian-config` → **System** → **Storage** → **Tune ZFS**).

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

# Option 2: Reload module (requires unmounting all ZFS filesystems)
zfs umount -a
rmmod zfs
modprobe zfs
```

=== "Viewing Current Settings"

Current settings can be viewed in the tuning interface or directly:

```bash
# View module parameters
cat /sys/module/zfs/parameters/zfs_arc_max
cat /sys/module/zfs/parameters/zfs_arc_min
cat /sys/module/zfs/parameters/zfs_dirty_data_max
cat /sys/module/zfs/parameters/zfs_txg_timeout

# View configuration file
cat /etc/modprobe.d/zfs.conf
```

=== "Reset to Defaults"

The tuning interface includes a "Reset to Defaults" option that:
- Removes custom configuration from `/etc/modprobe.d/zfs.conf`
- Resets all parameters to ZFS defaults
- Requires module reload to take effect

---

##### Key Features

###### Data Integrity
- **Copy-on-Write (CoW):** Prevents data corruption by never overwriting live data.
- **Checksumming:** Detects and corrects silent data corruption (bit rot).

###### Storage Management
- **Pooled Storage:** Eliminates the need for traditional partitions; all storage is managed dynamically.
- **Snapshots & Clones:** Creates instant backups without using extra storage.

###### Performance & Scalability
- **Efficient Compression & Deduplication:** Reduces storage usage without performance loss.
- **Dynamic Striping & Caching:** Distributes data across multiple disks for optimized read/write speeds.

###### Advanced Security
- **Native Encryption:** Supports dataset-level encryption for secure data storage.
- **RAID-Z:** A superior RAID alternative that prevents write-hole issues.

