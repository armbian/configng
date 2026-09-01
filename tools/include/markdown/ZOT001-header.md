**zot-cache** runs the [zot](https://zotregistry.dev/) OCI registry as a pull-through cache and scheduled mirror for `ghcr.io/armbian/**`, so a fleet of build nodes on the local network pulls every layer from local disk on the second access onward. Saves WAN bandwidth and turns multi-minute base-image pulls into seconds across the fleet.

**Key Features**

- Pull-through cache for `ghcr.io` (catch-all on-demand registry block)
- Scheduled pre-warm of `armbian/**` so cold pulls are already populated
- Preserves digests — ORAS artifacts, signatures, and SBOM referrers stay intact
- htpasswd + bcrypt auth: `builder` (read-only) for the fleet, `admin` (read/write) for management
- TLS-only listener; operator-supplied cert preferred, self-signed fallback offered
- GHCR PAT lives only in a `chmod 600` secrets file, never in `config.json` or logs

Official site: [https://zotregistry.dev/](https://zotregistry.dev/)
