ZRAM is a Linux kernel module that creates compressed RAM-based block devices. It extends available memory by compressing pages and storing them in RAM, giving you more usable memory at the cost of some CPU overhead. On devices with limited RAM, ZRAM can significantly improve system responsiveness and prevent out-of-memory conditions.

When enabling memory management, Armbian installs the `zram-config` package if not already present, enables the `armbian-zram-config` service, and configures optimal swappiness settings for ZRAM-based swapping.

*Key Features*

- **Memory Compression**: Transparent ZRAM-based swap that extends available memory without application changes
- **Parallel Compression**: Multiple ZRAM devices utilize all CPU cores for maximum throughput
- **Algorithm Choice**: Select optimal compression for your hardware (lzo, lz4, zstd, lzo-rle)
- **Adaptive Swapping**: Swappiness tuned for ZRAM's in-RAM characteristics
- **Memory Overcommitment**: Support for swap sizes larger than physical RAM
- **Safe Defaults**: Sensible defaults based on your system's memory size

---

Perfect for **ARM-based SBCs**, **small form-factor PCs**, and **servers** where physical RAM is limited and disk-based swap would cause excessive I/O.
