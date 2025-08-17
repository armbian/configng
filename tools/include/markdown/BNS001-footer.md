**Select Interface:**  
Choose the desired network interface, such as:

- `eth0` for wired Ethernet
- `wlan0` for wireless connections

If selecting a **wireless interface**:

- A list of available Access Points (APs) will be displayed.
- Select your preferred AP and enter the password when prompted.
- Leave the password field empty for open networks.

**IP Address Configuration:**  
Choose between:

- **DHCP (Dynamic Host Configuration Protocol):**  
  Automatically assigns an IP address.

- **Static IP:**  
  Manually enter the following details:
  - **MAC Address (optional):** Specify if you want to spoof the MAC address.
  - **IP Address:** Use CIDR notation (e.g., `192.168.1.10/24`).
  - **Route:** Default is `0.0.0.0/0`.
  - **Gateway:** Typically the router’s IP (e.g., `192.168.1.1`).
  - **DNS:** Default is `9.9.9.9`, but you can specify another.

**Finalize Configuration:**  

- Review and confirm your settings.
- The system will apply the configurations.
- Your network connection should then be fully established.

If you experience issues or prefer full control, follow the [manual networking setup guide](https://docs.armbian.com/User-Guide_Networking/).
