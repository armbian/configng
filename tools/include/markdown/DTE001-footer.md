=== "Features"

    - **Select and edit** any DTB file from the device tree directory
    - **Edit active DTB** directly based on the `fdtfile` setting in `/boot/armbianEnv.txt`
    - **Automatic backups** before every modification with timestamped filenames
    - **Restore from backup** to revert to a previous device tree
    - **Validation** of edited DTS source before applying changes
    - **View device tree info** including model, compatible strings, and DTC version

=== "Requirements"

    - Package: `device-tree-compiler` (installed automatically if missing)
    - Device tree directory: `/boot/dtb/`

=== "Backup location"

    Backups are stored in `/boot/dtb/backup/` with the naming format:

    ```
    <original-name>.dtb.<YYYYMMDD_HHMMSS>.bak
    ```
