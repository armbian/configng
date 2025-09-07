Long-Term Support (LTS) upgrades provide a well-tested and stable release of the underlying Linux distribution (Debian or Ubuntu). These versions receive security patches and critical bug fixes for an extended period, making them the recommended choice for production systems and for users who prioritize stability over new features.  

!!! Warning "Risks of Stable Upgrades"

    Even LTS → LTS upgrades (e.g., **Debian Bookworm → Trixie**, **Ubuntu Jammy → Noble**) carry some risks:

    - **Broken dependencies** – some packages may fail to upgrade or be removed.  
    - **Configuration overrides** – local changes may be replaced by defaults.  
    - **Hardware regressions** – drivers and firmware support can change.  
    - **Downtime** – failed upgrades may require console access, manual recovery, or a full reinstall.  

    Because Armbian integrates upstream Debian/Ubuntu with custom board support packages, upgrades may still trigger **unexpected breakage** on some devices.  

!!! Note "Best Practices"

    1. **Back up your data** (system and configuration).  
    2. **Test on a spare device or SD card** before upgrading production systems.  
    3. **Read the official release notes** of your target distribution:  
       - [Armbian FAQ: Can I upgrade my userspace flavor?](/User-Guide_FAQ/#can-i-upgrade-my-userspace-flavor-like-bullseye-to-bookworm-or-jammy-to-noble)  
       - [Debian upgrade notes](https://www.debian.org/releases/trixie/release-notes/upgrading.en.html)  
       - [Ubuntu release upgrade guide](https://documentation.ubuntu.com/server/how-to/software/upgrade-your-release/)  
    4. **Ensure you have console access** (serial, HDMI + keyboard, SSH).  
    5. **Consider fresh installs** if uptime and stability matter more than keeping the old environment.  

!!! Warning

    Distribution upgrades are experimental and **not supported by Armbian**. Use at your own risk.
