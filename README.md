# Pi-hole DNS Security Gateway 🛡️🚫

This repository describes the setup and configuration of [Pi-hole](https://pi-hole.net/) as a DNS Security Gateway. The goal is to create a safer and more private internet experience on the local network by blocking advertisements, trackers, and malicious domains at the DNS level. Additionally, DNS-over-HTTPS (DoH) is configured for outbound DNS queries to further enhance privacy.

## 🎯 Goals

* Block ads and trackers network-wide.
* Protect against malware domains and phishing sites.
* Increase privacy by encrypting DNS queries via DNS-over-HTTPS (DoH).
* Manage custom blocklists and whitelists.
* Provide a local DNS resolver to speed up queries and reduce reliance on external resolvers.

## 🛠️ Technologies Used

* [Pi-hole](https://pi-hole.net/)
* [DNS-over-HTTPS (DoH)](https://en.wikipedia.org/wiki/DNS_over_HTTPS) (e.g., using `cloudflared` or Unbound)
* Raspberry Pi (or any other Linux machine/VM/container)
* Docker (for Pi-hole installation, as per examples here)
* Custom blocklists

## ✨ Key Features/Highlights

* **Network-wide Ad Blocker:** Filters unwanted content for all devices on the network without needing client-side software.
* **Malware and Phishing Protection:** Utilizes curated blocklists to protect against known malicious domains.
* **DNS-over-HTTPS (DoH):** Encrypts outbound DNS queries to upstream DNS servers (e.g., Cloudflare, Google), preventing snooping by ISPs.
* **Custom Block/Whitelists:** Easy management of custom lists to fine-tune filtering behavior.
* **Dashboard and Statistics:** Clear web interface for monitoring DNS activity and blocking statistics.
* **Local DNS Caching:** Speeds up repeated DNS queries.
* **Improved Privacy:** Reduces the amount of data collected by trackers.

## 🏛️ Repository Structure

	pihole-dns-security-gateway/
	├── README.md
	├── docs/
	│   ├── doh-setup-cloudflared.md
	│   └── pihole-maintenance-tips.md
	├── config/
	│   ├── custom-blocklists.txt
	│   └── example-whitelist.txt
	├── docker/
	│   ├── docker-compose.yml
	│   └── .env.example
	└── scripts/
	└── backup-pihole-settings.sh


## 🚀 Getting Started / Configuration

Pi-hole can be installed in various ways. This repository focuses on configuration and enhancements, particularly using Docker.

1.  **Prerequisites:**
    * A host machine (Linux recommended, e.g., Raspberry Pi, a VM, or any server).
    * Docker and Docker Compose installed on the host.
2.  **Docker Setup:**
    * Navigate to the `docker/` directory.
    * Copy `.env.example` to `.env` and customize the variables (especially `WEBPASSWORD`, `FTLCONF_LOCAL_IPV4`, `TZ`).
    * Review the `docker-compose.yml`. It sets up Pi-hole and optionally `cloudflared` for DoH.
    * Start Pi-hole (and `cloudflared` if included in compose):
      ```bash
      cd docker
      docker-compose up -d
      ```
3.  **Pi-hole Initial Configuration:**
    * Access the Pi-hole admin interface: `http://<your_pihole_host_ip>/admin/` or `http://pi.hole/admin/` (if your clients use Pi-hole for DNS).
    * Log in with the `WEBPASSWORD` you set in the `.env` file.
    * **Upstream DNS Servers:**
        * If using the `cloudflared` service from the `docker-compose.yml`, Pi-hole should be configured to use `cloudflared#5053` as its upstream DNS server. This is often set as `127.0.0.1#5053` or `172.x.x.x#5053` (the `cloudflared` container's IP) if Pi-hole is configured to use the custom upstream DNS server `127.0.0.1#5053` or the IP of the cloudflared container on port 5053. The provided `docker-compose.yml` sets Pi-hole's `DNS1` and `DNS2` to use the `cloudflared` service name.
        * If not using `cloudflared` via Docker, configure your preferred upstream DNS servers (preferably DoH or DoT capable ones directly or via a local DoH client). See [`docs/doh-setup-cloudflared.md`](./docs/doh-setup-cloudflared.md) for manually setting up `cloudflared` if not using the Docker method.
4.  **Adding Custom Blocklists:**
    * In the Pi-hole admin interface, go to `Group Management` -> `Adlists`.
    * Add URLs from the [`config/custom-blocklists.txt`](./config/custom-blocklists.txt) file or other reputable sources.
    * Update Gravity: Go to `Tools` -> `Update Gravity` (or run `pihole -g` in the Pi-hole container: `docker exec pihole_container_name pihole -g`).
5.  **Network Configuration (Client-Side):**
    * Configure your DHCP server (usually on your router) to distribute the Pi-hole host's IP address as the DNS server to all clients on your network.
    * Alternatively, manually set the DNS server on individual devices to point to Pi-hole's IP address.
6.  **Maintenance and Backups:**
    * Regularly update Pi-hole and blocklists. See [`docs/pihole-maintenance-tips.md`](./docs/pihole-maintenance-tips.md).
    * Use the [`scripts/backup-pihole-settings.sh`](./scripts/backup-pihole-settings.sh) script to back up your Pi-hole settings.

## 🔮 Potential Improvements/Future Plans

* Integration of Unbound as a recursive DNS resolver for even greater privacy and independence.
* Setting up Conditional Forwarding for local hostname resolution if you have a local domain.
* Monitoring the Pi-hole instance with Prometheus and Grafana.
* Regularly reviewing and curating blocklists and whitelists.

