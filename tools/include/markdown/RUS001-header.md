RustDesk Server is a self-hosted remote desktop server solution that enables secure, peer-to-peer remote desktop connections without relying on public third-party servers. By hosting your own RustDesk Server, you maintain full control over your remote desktop infrastructure and data privacy.

**Key Components:**

- **hbbs (Rendezvous Server):** Manages peer discovery and connection initiation. This ID/Rendezvous server allows remote desktop clients to find each other using unique IDs. It operates on ports 21114-21116 for NAT traversal and WebSocket support.

- **hbbr (Relay Server):** Facilitates connections when direct peer-to-peer connections are not possible due to firewall or NAT restrictions. The relay server acts as an intermediary, routing traffic between clients on port 21117.

- **End-to-End Encryption:** All remote desktop traffic is encrypted using cryptographic keys generated during server setup. The server only routes encrypted data and cannot access your desktop session.

- **Privacy and Control:** Self-hosting ensures your remote connection data never leaves your infrastructure. No accounts, no tracking, and no dependency on external services.

**Key Features:**

- **Self-Hosted Architecture:** Complete independence from public RustDesk servers, ideal for corporate environments, privacy-conscious users, and air-gapped networks.

- **Cross-Platform Client Support:** RustDesk clients are available for Windows, Linux, macOS, Android, and iOS, providing flexibility in remote device access.

- **Lightweight Resource Usage:** The server containers are built with Rust and Go, consuming minimal system resources while handling multiple concurrent connections.

- **Automatic Key Generation:** The module automatically generates cryptographic key pairs (id_ed25519) during installation, securing all client-server communications.

- **Network Configuration:** The module automatically configures the hbbs server to use the hbbr relay server for fallback connections when direct P2P fails.

**Use Cases:**

- **Home Lab/Remote Access:** Access your home computers from anywhere without relying on third-party services.
- **Corporate Remote Support:** Provide IT support for employee workstations with full data sovereignty.
- **Headless Server Management:** remotely manage servers and systems without monitors or keyboards.
- **Privacy-Focused Remote Desktop:** Maintain complete control over your remote access infrastructure and logs.

For more information and client configuration, visit the official [RustDesk documentation](https://github.com/rustdesk/rustdesk/wiki/Server).
