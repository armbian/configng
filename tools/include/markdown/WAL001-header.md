Wallos is a self-hosted finance tracker and subscription management application. It helps you monitor recurring expenses, track subscriptions, and manage your financial commitments in one centralized location. With Wallos, you can visualize spending patterns, set renewal reminders, and take control of your recurring payments.

This Docker-based application runs as a lightweight web service, providing an intuitive interface for managing all your subscriptions and recurring expenses. The data is stored locally in SQLite database, ensuring your financial information remains private and under your control.

=== "Features"

    **Subscription Tracking**

    - Add and manage all your subscriptions (Netflix, Spotify, cloud services, etc.)
    - Track monthly, yearly, or one-time payments
    - Categorize expenses by type (streaming, software, utilities, etc.)
    - Set custom renewal dates and reminders

    **Financial Overview**

    - Visual dashboard showing total monthly/yearly expenses
    - Breakdown by category and service provider
    - Currency conversion support for international subscriptions
    - Export data to CSV for further analysis

    **Data Management**

    - Upload custom logos for service providers
    - Local SQLite database storage (no cloud dependency)
    - Automatic backups through Docker volume mounts
    - Import/export functionality for data portability

=== "Accessing Wallos"

    Once installed, access Wallos by navigating to:

    **http://your-server-ip:8282**

    On first access, you'll be guided through the initial setup:
    1. Create your admin account
    2. Configure currency preferences
    3. Set up default categories
    4. Start adding subscriptions

=== "Data Persistence"

    Wallos data is stored in Docker volumes for persistence:

    - **Database volume**: `/var/www/html/db` → stored at `${config_dir}/db`
    - **Logos volume**: `/var/www/html/images/uploads/logos` → stored at `${config_dir}/logos`

=== "Troubleshooting"

    **Container won't start**

    - Check port conflicts: `docker ps -a | grep wallos`
    - Verify volume mounts exist and have correct permissions
    - Review logs: `docker logs wallos`

    **Cannot access web interface**

    - Confirm container is running: `docker ps | grep wallos`
    - Check firewall rules allow port 8282
    - Verify correct IP address if accessing remotely

    **Data loss after restart**

    - Ensure Docker volumes are properly mounted
    - Check that persistence directories are not cleaned on reboot
    - Verify backup of `${config_dir}` before making changes

=== "View logs"

    ```sh
    docker logs -f wallos
    ```
