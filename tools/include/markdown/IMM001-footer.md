=== "Access to the service"

    Immich is accessible via HTTP on port **8077**:

    - URL: `http://<your.IP>:8077`

=== "Default credentials"

    - Email: *(set during initial setup)*
    - Password: *(set during initial setup)*

=== "Directories"

    - Uploads: `/armbian/immich/photos/upload/`
    - Thumbnails: `/armbian/immich/photos/thumbs/`
    - Profile images: `/armbian/immich/photos/profile/`
    - Library: `/armbian/immich/photos/library/`
    - Encoded videos: `/armbian/immich/photos/encoded-video/`
    - Backups: `/armbian/immich/photos/backups/`

=== "View logs"

    ```sh
    docker logs -f immich
    ```

=== "Immich vs Google Photos vs Synology Photos"

    | Feature / Aspect               | **Immich**                                | **Google Photos**                           | **Synology Photos**                         |
    |-------------------------------|-------------------------------------------|---------------------------------------------|---------------------------------------------|
    | **Hosting**                   | Self-hosted                               | Cloud (Google infrastructure)               | Self-hosted (on Synology NAS)               |
    | **Privacy & Control**         | Full control, private data storage        | Data stored and analyzed by Google          | Full control within your NAS environment    |
    | **Automatic Uploads**         | Yes (via mobile app)                      | Yes (via mobile app)                        | Yes (via mobile app or Synology Drive)      |
    | **Facial Recognition**        | Yes (on-device)                           | Yes (cloud-based)                           | Yes (on-device)                             |
    | **Object & Scene Detection**  | Yes (limited but improving)               | Yes (advanced AI)                           | Yes (basic)                                 |
    | **Web Interface**             | Yes (modern and responsive)               | Yes                                         | Yes                                         |
    | **Mobile Apps**               | Yes (iOS & Android)                       | Yes (iOS & Android)                         | Yes (iOS & Android)                         |
    | **Albums & Sharing**          | Yes (with public and private sharing)     | Yes (advanced sharing options)              | Yes                                         |
    | **Multi-user Support**        | Yes                                       | Limited (mostly single user)                | Yes (multi-user, tied to NAS users)         |
    | **Backup Original Quality**   | Yes (no compression)                      | Only with paid storage                      | Yes (NAS dependent)                         |
    | **Offline Access**            | Limited (depends on app setup)            | Yes (with sync)                             | Yes                                         |
    | **Open Source**               | Yes                                       | No                                          | No                                          |
    | **Hardware Requirement**      | Any Docker-capable server or NAS          | N/A (runs on Google’s cloud)                | Synology NAS required                       |
    | **Price**                     | Free (self-hosted, you pay for hardware)  | Free (with limitations) / Paid for storage  | Included with NAS, hardware cost required   |
