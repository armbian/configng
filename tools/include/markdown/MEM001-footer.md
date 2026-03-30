##### Key Features

###### Memory Compression
- **ZRAM Technology:** Compressed RAM-based swap devices that extend available memory
- **Transparent Operation:** Works automatically without application changes
- **Low Overhead:** Minimal CPU impact compared to disk I/O savings

###### Performance Optimization
- **Parallel Compression:** Multiple ZRAM devices utilize all CPU cores
- **Algorithm Choice:** Select optimal compression for your hardware (lzo for ARM)
- **Adaptive Swapping:** Swappiness tuned for ZRAM's in-RAM characteristics

###### Flexibility
- **Memory Overcommitment:** Support for swap sizes larger than physical RAM
- **Adjustable Parameters:** Fine-tune for specific workloads
- **Safe Defaults:** Armbian-config provides sensible defaults for your system

---

##### Troubleshooting

**ZRAM not working after enabling**

```bash
# Check if service is running
systemctl status armbian-zram-config

# Check if ZRAM devices exist
ls -la /dev/zram*

# Check active swap
swapon --show

# View system logs
journalctl -u armbian-zram-config -n 50
```

**High CPU usage with ZRAM**

This is normal during memory pressure. The CPU is compressing data instead of waiting on slow storage. However, if it's excessive:

- Reduce `ZRAM_PERCENTAGE` to limit swap size
- Check if a specific application is causing excessive memory usage
- Consider reducing `vm.swappiness` slightly (to 80-90)

**System still runs out of memory**

ZRAM increases effective memory size but has limits:

- Increase `ZRAM_PERCENTAGE` (up to 200-300% for read-heavy workloads)
- Check `MEM_LIMIT_PERCENTAGE` isn't too restrictive
- Identify and terminate memory-hungry applications
- Consider physical RAM upgrade if consistently hitting limits

**Compression algorithm not supported**

Some algorithms require specific kernel versions:

```bash
# Check available algorithms
cat /sys/block/zram0/comp_algorithm

# If your chosen algorithm isn't available, select one that is:
# lzo is universally available and recommended for ARM
```

**Changes not applying after save**

The ZRAM service must be restarted to apply changes:

```bash
systemctl restart armbian-zram-config
```

Or simply reboot the system.

**Poor performance after enabling ZRAM**

Rare, but can happen on very old/slow ARM boards:

- Try switching from `zstd` to `lzo` algorithm
- Reduce number of ZRAM devices (set to 1 or 2 instead of CPU cores)
- Lower `vm.swappiness` to 60-80
- As last resort, disable ZRAM and use traditional swap on storage

---

##### Advanced Configuration

**Manual configuration editing**

For advanced users, you can edit `/etc/default/armbian-zram-config` directly:

```bash
# Backup first
cp /etc/default/armbian-zram-config /etc/default/armbian-zram-config.bak

# Edit with nano or vim
nano /etc/default/armbian-zram-config

# Restart service to apply
systemctl restart armbian-zram-config
```

**ZRAM backing device**

For systems with fast NVMe storage, you can configure a backing device:

```bash
# Add to /etc/default/armbian-zram-config
ZRAM_BACKING_DEV=/dev/nvme0n1p4
```

This allows ZRAM to page out to fast storage when compressed memory is full. **Use with caution** - read the kernel documentation first.

**Monitoring ZRAM performance**

```bash
# View ZRAM statistics
cat /sys/block/zram0/mm_stat
# Format: mem_used_max mem_limit mem_used max_used same_pages compr_data_size ...

# Check compression ratio
echo "scale=2; $(cat /sys/block/zram0/orig_data_size) / $(cat /sys/block/zram0/compr_data_size)" | bc

# Monitor swap usage in real-time
watch -n 1 'swapon --show && free -h'
```

**Per-workload tuning**

- **Web servers:** Can use high ZRAM percentages (200-300%) as data is mostly read-only
- **Desktops:** Stick to 50% to balance performance and memory
- **Build systems:** May benefit from higher ZRAM (100%) to cache compilation artifacts
- **Databases:** Usually disable ZRAM and rely on database's own caching

---

##### Configuration Files

- **`/etc/default/armbian-zram-config`**: Main ZRAM configuration file
- **`/etc/sysctl.d/99-armbian-memory.conf`**: Swappiness and other VM parameters
- **`/usr/lib/systemd/system/armbian-zram-config.service`**: ZRAM service unit

##### Commands Reference

- **`systemctl status armbian-zram-config`**: Check ZRAM service status
- **`swapon --show`**: Display active swap devices including ZRAM
- **`zramctl`**: Show detailed ZRAM device statistics
- **`sysctl vm.swappiness`**: View current swappiness value
- **`cat /sys/block/zram0/*`**: Access detailed ZRAM device information

##### Related Documentation

- [Armbian Memory Management](https://docs.armbian.com/User-Guide_Fine-Tuning/)
- [Kernel ZRAM Documentation](https://www.kernel.org/doc/Documentation/blockdev/zram.txt)
- [Linux Swappiness Tuning](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/performance_tuning_guide/s-memory)
