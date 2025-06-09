#!/bin/bash

# backup-pihole-settings.sh
# A simple script to back up Pi-hole settings using the Teleporter feature.
# This script should ideally be run on the Pi-hole host or a machine
# that can execute 'docker exec' into the Pi-hole container.

# --- Configuration ---
# Name of your Pi-hole Docker container (if using Docker)
PIHOLE_CONTAINER_NAME="pihole" # Adjust if your container name is different

# Backup directory on the host machine
BACKUP_DIR="/opt/pihole_backups" # Create this directory: sudo mkdir -p /opt/pihole_backups

# Filename for the backup (timestamp will be appended)
BACKUP_FILENAME_PREFIX="pihole-teleporter"

# Number of old backups to keep (set to 0 to keep all)
KEEP_BACKUPS=7

# --- Script ---
DATE_SUFFIX=$(date "+%Y%m%d-%H%M%S")
BACKUP_FILE="${BACKUP_FILENAME_PREFIX}_${DATE_SUFFIX}.tar.gz"
FULL_BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"
if [ ! -d "${BACKUP_DIR}" ]; then
    echo "ERROR: Backup directory ${BACKUP_DIR} could not be created. Please check permissions."
    exit 1
fi

echo "Starting Pi-hole settings backup..."

# Determine if running in Docker or native
IS_DOCKER=false
if command -v docker &> /dev/null && docker ps -q --filter "name=^/${PIHOLE_CONTAINER_NAME}$" | grep -q .; then
    IS_DOCKER=true
fi

if ${IS_DOCKER}; then
    echo "Pi-hole container '${PIHOLE_CONTAINER_NAME}' found. Using docker exec for backup."
    # The teleporter will create the backup inside the container. We need to copy it out.
    # Pi-hole teleporter creates the file in the current directory *inside the container*.
    # Let's target /tmp inside the container for simplicity, then copy.
    docker exec "${PIHOLE_CONTAINER_NAME}" pihole -a -t "/tmp/${BACKUP_FILE}"
    if [ $? -eq 0 ]; then
        echo "Teleporter backup created inside container at /tmp/${BACKUP_FILE}."
        docker cp "${PIHOLE_CONTAINER_NAME}:/tmp/${BACKUP_FILE}" "${FULL_BACKUP_PATH}"
        if [ $? -eq 0 ]; then
            echo "Backup successfully copied to ${FULL_BACKUP_PATH}"
            # Clean up the backup file inside the container
            docker exec "${PIHOLE_CONTAINER_NAME}" rm "/tmp/${BACKUP_FILE}"
        else
            echo "ERROR: Failed to copy backup from container to host."
            exit 1
        fi
    else
        echo "ERROR: Pi-hole teleporter command failed inside container."
        exit 1
    fi
else
    echo "Pi-hole container not found or Docker not used. Assuming native Pi-hole installation."
    # Ensure pihole command is in PATH or provide full path if needed.
    # The backup will be created in the directory where this script is run,
    # so we move it to the target backup directory.
    TEMP_BACKUP_PATH="./${BACKUP_FILE}"
    pihole -a -t "${TEMP_BACKUP_PATH}"
    if [ $? -eq 0 ]; then
        mv "${TEMP_BACKUP_PATH}" "${FULL_BACKUP_PATH}"
        if [ $? -eq 0 ]; then
            echo "Backup successfully created at ${FULL_BACKUP_PATH}"
        else
            echo "ERROR: Failed to move backup to ${FULL_BACKUP_PATH}"
            # Attempt to clean up temp file if move failed but backup was created
            if [ -f "${TEMP_BACKUP_PATH}" ]; then
                rm "${TEMP_BACKUP_PATH}"
            fi
            exit 1
        fi
    else
        echo "ERROR: Pi-hole teleporter command failed for native installation."
        exit 1
    fi
fi

# Prune old backups
if [ ${KEEP_BACKUPS} -gt 0 ]; then
    echo "Pruning old backups, keeping last ${KEEP_BACKUPS} files..."
    # Count current backups
    CURRENT_BACKUP_COUNT=$(ls -1q "${BACKUP_DIR}/${BACKUP_FILENAME_PREFIX}"*.tar.gz 2>/dev/null | wc -l)
    if [ ${CURRENT_BACKUP_COUNT} -gt ${KEEP_BACKUPS} ]; then
        # List files by modification time (oldest first), then select files to delete
        ls -1tr "${BACKUP_DIR}/${BACKUP_FILENAME_PREFIX}"*.tar.gz | head -n -$((KEEP_BACKUPS)) | xargs -r rm -v
        echo "Old backups pruned."
    else
        echo "No old backups to prune (found ${CURRENT_BACKUP_COUNT}, keeping ${KEEP_BACKUPS})."
    fi
fi

echo "Pi-hole settings backup process finished."
exit 0