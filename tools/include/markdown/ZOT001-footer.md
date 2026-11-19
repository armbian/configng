=== "Access to the service"

    TLS on port **5000** (default; configurable at install):

    - URL: `https://<your.IP>:5000`
    - Catalog: `https://<your.IP>:5000/v2/_catalog` (basic auth)
    - Credentials: `builder` (read-only) shown once at install

=== "Client configuration (build nodes)"

    Add the cache to docker:

    ```sh
    sudo tee /etc/docker/daemon.json <<EOF
    {
      "registry-mirrors": ["https://<cache-host>:5000"]
    }
    EOF
    sudo systemctl restart docker
    ```

    Or for `oras` / direct pulls:

    ```sh
    oras login <cache-host>:5000 -u builder -p '<builder-pw>'
    oras pull <cache-host>:5000/armbian/<pkg>:<tag>
    ```

=== "Directories"

    - Config:       `/etc/zot/config.json`
    - htpasswd:     `/etc/zot/htpasswd`
    - GHCR secret:  `/etc/zot/sync-credentials.json` (chmod 600)
    - TLS:          `/etc/zot/certs/`
    - Tunables:     `/etc/zot/zot-cache.env`
    - Blob store:   `/pool/registry` (configurable at install)

=== "Egress firewall (this host)"

    Pull-through requires BOTH endpoints reachable:

    - `ghcr.io` — manifest service
    - `pkg-containers.githubusercontent.com` — Fastly blob CDN GHCR redirects to

    Allowing only `ghcr.io` makes manifests resolve but every layer fails with `unknown blob`.

=== "Storage notes"

    If the blob store sits on **ZFS**:

    ```sh
    zfs set recordsize=1M  <dataset>
    zfs set compression=lz4 <dataset>
    zfs set atime=off       <dataset>
    zfs set dedup=off       <dataset>
    ```

    `zot` dedups blobs itself — ZFS dedup on top only wastes RAM. This module does **not** tune storage automatically.

=== "TLS notes"

    The install offers a self-signed cert as a fallback. If you accept it, distribute `/etc/zot/certs/zot.crt` to each build node's trust store. **`tlsVerify: false` / `--insecure` is not an acceptable fleet default** — it silently disables mirror integrity.

=== "View logs"

    ```sh
    docker logs -f zot-cache
    ```

=== "Manage the service"

    ```sh
    docker exec -it zot-cache sh
    ```
