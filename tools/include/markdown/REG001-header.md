**registry-cache** is a read-only cache of one OCI registry, `ghcr.io` by default. It downloads each artifact from the registry once. Later pulls come from local disk.

Armbian stores build artifacts and git trees on `ghcr.io`. Build hosts with many runners download them once.

**Key Features**

- Read-only cache, single port (`5000`), single container ([distribution registry](https://distribution.github.io/distribution/))
- Cache expiry: 7 days
- Access: this host and its Docker containers. Set `BIND_ADDRESS` at install to serve a LAN.
