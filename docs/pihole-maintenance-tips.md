# Pi-hole Maintenance Tips

Regular maintenance ensures your Pi-hole instance runs smoothly, stays secure, and effectively blocks unwanted content.

## 1. Update Pi-hole Core, Web Interface, and FTL

Pi-hole components are updated regularly with new features, bug fixes, and security patches.

* **Via Web Interface:**
    The Pi-hole admin dashboard usually indicates when updates are available at the bottom of the page.
* **Via Command Line (inside the container or on the host if not Dockerized):**
    ```bash
    # To update Pi-hole (Core, Web, FTL)
    pihole -up
    ```
    If running Pi-hole in Docker, you typically update by pulling the latest Docker image and recreating the container:
    ```bash
    # Navigate to your Pi-hole docker-compose directory
    docker-compose pull # Pulls the latest image defined in your docker-compose.yml (e.g., pihole/pihole:latest)
    docker-compose up -d --remove-orphans # Recreates the container with the new image
    ```
    It's good practice to back up your settings before a major update (see Backups section).

## 2. Update Gravity (Blocklists)

Your blocklists need to be updated to fetch the latest definitions of ad and tracker domains.

* **Via Web Interface:**
    Go to `Tools` -> `Update Gravity`. Click the "Update" button.
* **Via Command Line:**
    ```bash
    pihole -g
    ```
    This is often scheduled automatically by Pi-hole (e.g., weekly). You can check `Settings` -> `System` in the web UI to see the cron script for Gravity updates (`/etc/cron.d/pihole`).

## 3. Review and Manage Blocklists (Adlists)

* Periodically review your adlists (`Group Management` -> `Adlists`).
* Remove any lists that are no longer maintained or cause too many false positives.
* Consider adding new, reputable adlists from sources like [The Firebog](https://firebog.net/). (See `config/custom-blocklists.txt` for examples).

## 4. Manage Whitelist and Blacklist

* **Whitelist:** If a legitimate website or service is being blocked, add its domain(s) to the whitelist (`Domain Management` -> `Whitelist`).
* **Blacklist (Regex/Wildcard):** If you find specific domains or patterns you always want to block, add them to the blacklist (`Domain Management` -> `Blacklist` or `Regex Filters`).
* Refer to `config/example-whitelist.txt` for common domains that might need whitelisting.

## 5. Monitor Query Log and System Performance

* **Query Log:** Regularly check the query log (`Query Log`) to see what's being blocked and allowed. This can help identify:
    * Domains that need whitelisting.
    * New ad/tracker domains that might need to be added to a local blacklist or a blocklist.
    * Devices making unusual DNS queries.
* **Dashboard Stats:** Keep an eye on the dashboard for overall performance, percentage blocked, and top clients/domains.
* **Host System:** Ensure the underlying system (Raspberry Pi, VM, server) running Pi-hole has enough resources (CPU, RAM, disk space).

## 6. Back Up Pi-hole Settings

Regularly back up your Pi-hole configuration. This includes your adlists, whitelist, blacklist, regex filters, and other settings.

* **Using Pi-hole Teleporter:**
    In the web interface, go to `Settings` -> `Teleporter`. Click "Backup" to download a `pi-hole-teleporter_*.tar.gz` file.
* **Via Command Line (for Teleporter):**
    ```bash
    pihole -a -t your_backup_name.tar.gz
    ```
* **Manual Backup (if using Docker with persistent volumes):**
    The most critical data is stored in the volumes mapped in your `docker-compose.yml` (e.g., `./etc-pihole/` and `./etc-dnsmasq.d/` or the single data volume in the provided example). You can back up these directories.
    The script in `scripts/backup-pihole-settings.sh` uses the teleporter function.

## 7. Prune Old Query Logs (Optional)

Pi-hole logs DNS queries. Over time, the log database (`/etc/pihole/pihole-FTL.db`) can grow large.
* Pi-hole FTL has built-in mechanisms to manage log size (`MAXDBDAYS` in `/etc/pihole/pihole-FTL.conf`). The default is 365 days. You can adjust this if needed.
* You can flush logs via the web interface (`Settings` -> `System` -> `Flush logs`) or command line (`pihole -f`). **This will delete your query history.**

## 8. Keep the Host System Secure

* Apply security updates to the operating system of the Pi-hole host.
* If using SSH, ensure it's secured (e.g., key-based authentication, Fail2Ban).

## 9. Check Pi-hole Diagnosis Log

If you encounter issues, the Pi-hole diagnosis log can be very helpful.
* **Via Command Line:**
    ```bash
    pihole -d
    ```
    You can choose to upload the log for support or view it locally.

By following these maintenance tips, you can keep your Pi-hole running efficiently and effectively.