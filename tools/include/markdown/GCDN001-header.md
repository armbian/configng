**git_cdn** is a caching git+HTTP(s) proxy that mirrors an upstream git server (GitHub) close to your build/CI hosts. The first clone or fetch of a repository populates the cache; every subsequent clone/fetch of the same repo from any host on the LAN pulls only new objects from upstream — saving WAN bandwidth and speeding up repeated GitHub clones.

**Key Features**

- git+http(s) proxy in front of `https://github.com`
- Single-port (`8000`), single-container deployment
- Pack-level object cache, configurable size (default 500 GB)
- Survives container restart — cache lives on a host bind-mount
