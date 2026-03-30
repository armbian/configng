=== "Recommended Settings"

    Settings are automatically selected based on system memory:

    | System | ZRAM Size | Memory Limit | Swappiness |
    |--------|-----------|--------------|------------|
    | < 4 GB RAM | 50% | 50% | 100 |
    | 4+ GB RAM | 25% | 25% | 80 |

    - **Max Devices**: Set to CPU core count (capped at 8)
    - **Algorithm**: lzo (best for ARM), lz4 (fast on x86), zstd (best ratio, slower)

=== "Tuning Parameters"

    - **ZRAM Percentage** (10-300%): Swap space relative to physical RAM. With 50% on a 2GB system you get 1GB of swap, but compression (2:1 to 3:1) effectively holds 2-3GB
    - **Memory Limit** (10-100%): Prevents ZRAM from consuming too much physical RAM. Should generally match ZRAM percentage
    - **Swappiness** (1-100): How aggressively the kernel swaps to ZRAM. Use 80-100 for ZRAM (unlike disk swap where 60 is default)
    - **Max Devices** (1-8): Number of ZRAM devices, usually one per CPU core for parallel compression

=== "Troubleshooting"

    - **ZRAM not working**: Check `systemctl status armbian-zram-config` and `swapon --show`
    - **High CPU usage**: Normal during memory pressure. Reduce `ZRAM_PERCENTAGE` or switch to `lzo` algorithm
    - **Still out of memory**: Increase `ZRAM_PERCENTAGE` (up to 200-300% for read-heavy workloads)
    - **Algorithm not supported**: Run `cat /sys/block/zram0/comp_algorithm` to see available options
    - **Changes not applying**: Run `systemctl restart armbian-zram-config` or reboot

=== "Advanced Configuration"

    Edit `/etc/default/armbian-zram-config` directly for advanced options:

    ```sh
    # Backup first
    cp /etc/default/armbian-zram-config /etc/default/armbian-zram-config.bak

    # Edit configuration
    nano /etc/default/armbian-zram-config

    # Restart to apply
    systemctl restart armbian-zram-config
    ```

    **ZRAM backing device** - for systems with fast NVMe storage:

    ```sh
    # Add to /etc/default/armbian-zram-config
    ZRAM_BACKING_DEV=/dev/nvme0n1p4
    ```

    **Monitoring**:

    ```sh
    # Check compression ratio
    echo "scale=2; $(cat /sys/block/zram0/orig_data_size) / $(cat /sys/block/zram0/compr_data_size)" | bc

    # Monitor swap usage
    watch -n 1 'swapon --show && free -h'
    ```

=== "Configuration Files"

    - **`/etc/default/armbian-zram-config`**: Main ZRAM configuration
    - **`/etc/sysctl.d/99-armbian-memory.conf`**: Swappiness and VM parameters
    - **`zramctl`**: Show detailed ZRAM device statistics
    - **`swapon --show`**: Display active swap devices including ZRAM
