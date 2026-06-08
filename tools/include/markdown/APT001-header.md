**apt-cacher-ng** is a caching HTTP proxy for Debian and Ubuntu apt repositories. The first host on the LAN to fetch a `.deb` populates the cache; every subsequent `apt-get install` / `apt-get dist-upgrade` on any other host serves the same package from local disk — saving WAN bandwidth and turning multi-minute upgrades into seconds.

**Key Features**

- Transparent HTTP proxy in front of `deb.debian.org` / `archive.ubuntu.com` / vendor mirrors
- Single-port (`3142`), single-container deployment
- Per-package hit-rate report at `/acng-report.html`
- Survives container restart — cache lives on a host bind-mount
