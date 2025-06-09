# Setting up DNS-over-HTTPS (DoH) with `cloudflared` for Pi-hole

DNS-over-HTTPS (DoH) encrypts your DNS queries, preventing third parties (like your ISP) from easily snooping on the websites you visit. This guide explains how to set up `cloudflared`, a DNS proxy by Cloudflare, to act as a DoH client for your Pi-hole instance.

**Note:** The `docker-compose.yml` provided in the `docker/` directory of this repository already includes an option to run `cloudflared` alongside Pi-hole and configures Pi-hole to use it. This guide is useful if you are setting up `cloudflared` manually on the Pi-hole host (not in Docker) or want a deeper understanding.

## Method 1: Using `cloudflared` via Docker (Recommended with Pi-hole Docker Setup)

The `docker-compose.yml` in the `docker/` directory of this project includes a service for `cloudflared`.
Pi-hole is then configured (via environment variables in the `docker-compose.yml`) to use `cloudflared` as its upstream DNS server.

* **`cloudflared` service in `docker-compose.yml`:**
    ```yaml
    # services:
    #   cloudflared:
    #     image: cloudflare/cloudflared:latest
    #     container_name: cloudflared
    #     restart: unless-stopped
    #     command: proxy-dns --port 5053 --upstream [https://1.1.1.1/dns-query](https://1.1.1.1/dns-query) --upstream [https://1.0.0.1/dns-query](https://1.0.0.1/dns-query)
    #     networks:
    #       pihole_network: # Ensure it's on the same network as Pi-hole
    #         ipv4_address: 172.20.0.3 # Example static IP, adjust subnet as needed
    ```
* **Pi-hole service environment variables for DNS:**
    ```yaml
    # environment:
    #   DNS1: 172.20.0.3#5053 # Points to the cloudflared container IP and port
    #   DNS2: "" # Or another DoH provider via cloudflared, or leave blank
    ```
When using this Docker Compose setup, `cloudflared` listens on port `5053` within the Docker network. Pi-hole is configured to send its DNS queries to `cloudflared` on this port. No further manual `cloudflared` setup is typically needed on the host.

## Method 2: Manual `cloudflared` Installation on the Pi-hole Host

If you are not running Pi-hole in Docker, or want to run `cloudflared` directly on the host system where Pi-hole is installed (e.g., a Raspberry Pi with Pi-hole installed via its script).

1.  **Install `cloudflared`:**
    Follow the official Cloudflare documentation to install `cloudflared` for your operating system:
    [https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/)

    For Debian/Raspberry Pi OS (example):
    ```bash
    # Download the .deb package (check for the latest version)
    wget [https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm.deb](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm.deb) # For ARM (Raspberry Pi)
    # For amd64: wget [https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb](https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb)
    sudo dpkg -i cloudflared-linux-arm.deb
    # If dependencies are missing:
    # sudo apt --fix-broken install
    ```

2.  **Configure `cloudflared` as a DNS Proxy:**
    You can run `cloudflared` as a systemd service. Create a configuration file for `cloudflared` at `/etc/cloudflared/config.yml` (or `/usr/local/etc/cloudflared/config.yml` depending on installation):

    ```yaml
    # /etc/cloudflared/config.yml
    proxy-dns: true
    port: 5053 # Port cloudflared will listen on for DNS queries from Pi-hole
    address: 127.0.0.1 # Listen only on localhost
    upstream:
      - [https://1.1.1.1/dns-query](https://1.1.1.1/dns-query) # Cloudflare DNS
      - [https://1.0.0.1/dns-query](https://1.0.0.1/dns-query) # Cloudflare DNS (secondary)
      # You can choose other DoH providers:
      # - [https://dns.google/dns-query](https://dns.google/dns-query)
      # - [https://dns.quad9.net/dns-query](https://dns.quad9.net/dns-query)
    ```

3.  **Set up `cloudflared` as a Systemd Service:**
    ```bash
    sudo cloudflared service install # This might use the default config path
    # If you used a custom config path, you might need to adjust the service file or specify user.
    # Example for /etc/cloudflared/config.yml:
    # sudo cloudflared --config /etc/cloudflared/config.yml service install
    ```
    Enable and start the service:
    ```bash
    sudo systemctl enable cloudflared
    sudo systemctl start cloudflared
    ```
    Check status:
    ```bash
    sudo systemctl status cloudflared
    ```

4.  **Configure Pi-hole to Use `cloudflared`:**
    * Log in to your Pi-hole admin interface.
    * Go to `Settings` -> `DNS`.
    * **Uncheck all upstream DNS server options on the left (IPv4 and IPv6).**
    * In the "Upstream DNS Servers" section on the right, under "Custom 1 (IPv4)", enter:
        `127.0.0.1#5053`
    * Leave "Custom 2 (IPv4)" and IPv6 custom fields blank, or add another local DoH proxy if you have one.
    * Click `Save`.

5.  **Test the Setup:**
    * Clear your computer's DNS cache.
    * Try Browse some websites.
    * Check the Pi-hole Query Log. You should see queries being forwarded to `127.0.0.1#5053`.
    * You can also test DNS resolution directly using `dig` or `nslookup` against `127.0.0.1` on port `5053` from the Pi-hole host:
        ```bash
        dig @127.0.0.1 -p 5053 google.com
        ```

## Important Notes

* **Port Conflicts:** Ensure port `5053` (or whatever port you choose for `cloudflared`) is not already in use.
* **Firewall:** If your Pi-hole host has a firewall, ensure `cloudflared` can make outbound HTTPS connections (port 443). Pi-hole itself (port 53) needs to be reachable by clients on your LAN. `cloudflared` (port 5053) only needs to be reachable by Pi-hole (localhost).
* **Updating `cloudflared`:** Remember to update `cloudflared` periodically to get the latest features and security fixes.
    ```bash
    # For .deb installations:
    # sudo apt update
    # sudo apt upgrade cloudflared
    # For direct binary: download the new binary and replace the old one.
    ```

By using `cloudflared`, your DNS queries from Pi-hole to upstream resolvers will be encrypted, enhancing your network's privacy.