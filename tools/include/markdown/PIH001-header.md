**Pi-hole** is a network-wide ad blocker that acts as a DNS (Domain Name System) sinkhole. It blocks connections to known ad servers, trackers, and malicious domains across all devices in your network, without requiring any browser extensions or client-side software.

## Pi-hole Explained

- **DNS-Based Filtering**
Pi-hole intercepts DNS queries made by devices on your network. When a domain is requested, Pi-hole checks it against a set of blocklists. If the domain is known to serve ads or track user activity, Pi-hole blocks the request, preventing unwanted content from loading.

- **Customizable Blocklists**
You can choose from various community-maintained blocklists or add your own. These lists contain domains associated with ads, trackers, malware, or other undesirable content.

- **Whole-Network Protection**
Once Pi-hole is configured as your network’s DNS server, all devices - smartphones, laptops, smart TVs, and IoT devices - are automatically protected. No additional configuration or software is required on the individual devices.

- **Built-in Recursive DNS with Unbound**
For added privacy and full DNS resolution control, [Unbound](#unbound) is installed and enabled by default during Pi-hole installation. Unbound functions as a local recursive DNS resolver, fetching responses directly from authoritative DNS servers rather than relying on upstream providers. This minimizes third-party exposure and can improve query performance.

- **Web Interface**
Pi-hole includes a web-based dashboard that provides real-time visibility into DNS activity. The interface allows you to view statistics, manage blocklists, whitelist domains, and configure settings with ease.

- **Privacy and Performance Benefits**
By blocking unwanted domains at the DNS level, Pi-hole reduces page load times, lowers bandwidth usage, and enhances user privacy by preventing tracking scripts and ads from reaching client devices.

- **Platform Compatibility**
Pi-hole can be installed on a variety of platforms. It runs well on lightweight systems such as **Armbian Minimal**, but is also available as a Docker container and supports deployment on most Linux-based environments.

Pi-hole offers an effective and centralized way to enhance privacy and reduce unwanted content across your entire network.
