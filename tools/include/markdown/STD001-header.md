Stable / LTS upgrades move your system to a newer release of Debian or Ubuntu, bringing updated system packages along with long-term security fixes and bug patches. This makes them the safest choice for reliable, everyday use.

!!! Warning "Risks of Stable Upgrades"

    Distribution upgrades are experimental and **not supported by Armbian**. Use at your own risk.

    Even LTS → LTS upgrades (e.g., **Debian Bookworm → Trixie**, **Ubuntu Jammy → Noble**) carry some risks:

    - **Broken dependencies** – some packages may fail to upgrade or be removed.  
    - **Configuration overrides** – local changes may be replaced by defaults.  
    - **Downtime** – failed upgrades may require console access, manual recovery, or a full reinstall.  

    Because Armbian integrates upstream Debian/Ubuntu with custom board support packages, upgrades may still trigger **unexpected breakage** on some devices.  
