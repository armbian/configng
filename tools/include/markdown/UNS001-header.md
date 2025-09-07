Non-LTS releases are intended for **developers, testers, and enthusiasts** who want the latest features — **not for production systems**.  

!!! Warning "Risks of Unstable Upgrades"

    Distribution upgrades are experimental and **not supported by Armbian**. Use at your own risk.

    - **High chance of breakage** – dependencies, bootloader, or kernel may fail.  
    - **Short lifecycle** – requires frequent re-upgrades (every ~6–9 months).  
    - **Unfinished features** – packages may be experimental or not fully supported.  
    - **Armbian compatibility** – integration with board support packages is less tested.  

    Using unstable upgrades without proper backups or recovery options may result in a **non-bootable system**.  

!!! Note "Best Practices"

    1. **Only attempt on non-production devices**.  
    2. **Back up** data and configs before testing.  
    3. **Have serial console access** in case recovery is needed.  
    4. **Expect reinstallations** – unstable paths often break beyond repair.  
    5. **Use containers or chroots** for testing instead of upgrading the whole OS.
