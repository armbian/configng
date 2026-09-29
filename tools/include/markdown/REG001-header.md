**registry-cache** is a read-only cache of one OCI registry, `ghcr.io` by default. It stores downloaded content on local disk. Tag lookups still go to the registry, so the cache needs access to the registry.

Armbian stores build artifacts and git trees on `ghcr.io`. Build hosts with many runners download each artifact once.

**Key Features**

- Read-only cache, single port (`5000`), single container ([distribution registry](https://distribution.github.io/distribution/))
- Cache expiry: 7 days
- Access: this host and its Docker containers. Set `BIND_ADDRESS` at install to serve a LAN.

!!! warning "Plain HTTP"
    The cache has no TLS and no authentication. Serve a LAN only when you trust the LAN.
