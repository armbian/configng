ZRAM is a Linux kernel module that creates compressed RAM-based block devices. It provides an effective way to extend available memory on systems with limited RAM by compressing memory pages and storing them in RAM, effectively giving you more usable memory at the cost of some CPU overhead. On ARM devices with 1-2GB of RAM, ZRAM can significantly improve system responsiveness and prevent out-of-memory conditions.

When enabling memory management, Armbian installs the `zram-config` package if not already present, enables the `armbian-zram-config` service, and configures optimal swappiness settings for ZRAM-based swapping. The service creates multiple ZRAM devices (one per CPU core by default) and uses them as compressed swap space.

=== "ZRAM Size Percentage"

    The **ZRAM percentage** determines how much swap space is created relative to physical RAM.

    **Recommended Settings:**

    - **Small systems (1-2 GB RAM):** 50% of RAM
    - **Medium systems (3-4 GB RAM):** 50% of RAM
    - **Large systems (8+ GB RAM):** 25% of RAM

    **Understanding ZRAM Percentage:**

    With 50% ZRAM on a 2GB system, you get 1GB of swap space. But since data is compressed (typically 2:1 to 3:1 ratio), this can effectively hold 2-3GB of data. This means your 2GB system can behave like a 4-5GB system.

    **Memory Overcommitment:**

    You can safely set ZRAM percentage higher than 100% on systems that primarily use read-only data (like web servers). The kernel will only store what fits, and excess data won't be swapped to slow disk storage.

    **Impact:**

    - Higher percentage = more swap space available
    - Too high (>200%) may waste CPU cycles on rarely-used data
    - ZRAM compression ratio of 2:1 to 3:1 is typical

=== "Memory Limit Percentage"

    The **memory limit** prevents ZRAM from consuming too much physical RAM.

    **Recommended Setting:** Same as ZRAM percentage (50% for most systems)

    **Why This Matters:**

    Without a limit, ZRAM could theoretically use all RAM for compressed data storage. The limit ensures ZRAM doesn't crowd out active applications.

    **Typical Values:**

    - **50%:** Balanced - allows aggressive swapping while preserving RAM for apps
    - **25%:** Conservative - less swapping, more RAM for applications
    - **100%:** Maximum ZRAM usage (only use if you understand the implications)

    **Impact:**

    - Lower limit = more RAM for applications, less compressed swap
    - Higher limit = more compressed swap, less RAM for applications
    - Should generally match ZRAM percentage for consistency

=== "ZRAM Devices and Algorithms"

    The number of ZRAM devices and compression algorithm significantly affect performance.

    **Max Devices:**

    - **Recommended:** Set to number of CPU cores
    - **Range:** 1-8 devices
    - **Multiple devices** allow parallel compression on multi-core systems

    **Compression Algorithms:**

    - **lzo (recommended for ARM):** Fastest on ARM, good compression ratio
    - **lz4:** Slightly faster than lzo on x86, less compression
    - **zstd:** Best compression ratio, slower (not recommended for swap)
    - **lzo-rle:** Even faster version of lzo with slightly less compression

    **Algorithm Selection:**

    For swap on ARM systems, **lzo** is recommended because it offers the best balance of speed and compression. The CPU overhead of compressing data is lower than the cost of reading from storage.

=== "Swappiness"

    **Swappiness** controls how aggressively the kernel swaps data to ZRAM.

    **Recommended Settings:**

    - **ZRAM systems:** 80-100 (aggressive swapping to compressed RAM)
    - **Traditional swap:** 60 (default kernel setting)
    - **Desktops with SSD:** 10-20 (minimize writes)

    **Understanding Swappiness:**

    - **Value 1:** Swap only to avoid out-of-memory (minimal swapping)
    - **Value 60:** Default kernel behavior
    - **Value 100:** Swap aggressively to ZRAM (recommended for ZRAM)

    **Why High Swappiness with ZRAM?**

    Unlike traditional swap on disk, ZRAM swap is in RAM and compressed. Swapping to ZRAM is much faster than disk I/O, so aggressive swapping improves performance by keeping more data in fast (compressed) memory.

    **Impact:**

    - Too low (1-30): Underutilized ZRAM, may run out of memory
    - Optimal (80-100): Maximizes ZRAM benefits
    - Higher than 100: Not valid

=== "Applying Configuration"

    Configuration is saved to `/etc/default/armbian-zram-config` and requires restarting the ZRAM service:

    ```bash
    # Restart ZRAM service to apply changes
    systemctl restart armbian-zram-config

    # Or reboot (simpler)
    reboot
    ```

    **Note:** Restarting the service briefly disables swap. Avoid making changes while running memory-intensive workloads.

=== "Reset to Defaults"

    The tuning interface includes a "Reset to Defaults" option that:

    - Restores recommended settings for your system memory size
    - Sets ZRAM percentage to 50% (25% for 4GB+ systems)
    - Configures optimal swappiness (100 for ZRAM)
    - Sets max devices to CPU core count
