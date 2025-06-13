#!/bin/bash
set -e

# Set PATH explicitly for cron environment
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

HOME_DIR="/home/horazmic"

SYSTEM_NAME=$(/usr/bin/hostname)
echo -e "\n=== System update setup started at $(date) on $SYSTEM_NAME ===\n"

# Log file paths
LOG_FILE="$HOME_DIR/system_update.log"
REMOTE_DIR="/mnt/horazmic_vault/code/storage/system-update-logs"
REMOTE_LOG_FILE="$REMOTE_DIR/${SYSTEM_NAME}_system_update.log"

is_remote_available() {
    [ -d "$REMOTE_DIR" ] && /usr/bin/touch "$REMOTE_LOG_FILE" 2>/dev/null
}


# Set up logging
if is_remote_available; then
    echo "Remote log available: Logging to both local and remote files."
    exec > >(/usr/bin/tee -a "$LOG_FILE" "$REMOTE_LOG_FILE") 2>&1
else
    echo "Remote log unavailable: Logging to local file only."
    echo "You can setup remote by running the setup-remote-share.sh"
    exec > >(/usr/bin/tee -a "$LOG_FILE") 2>&1
fi

echo -e "\n=== System update started at $(date) on $SYSTEM_NAME ===\n"

error_handler() {
    echo "Error occurred in script at line: $1"
    exit 1
}
trap 'error_handler $LINENO' ERR

# Update and upgrade
/usr/bin/apt-get update
/usr/bin/apt-get upgrade -y
/usr/bin/apt-get autoremove -y
/usr/bin/apt-get clean

# Flatpak update if available
if [ -x /usr/bin/flatpak ]; then
    echo -e "\nFlatpak is installed, proceeding with update."
    /usr/bin/flatpak update -y || echo "Flatpak update failed."
else
    echo "Flatpak not installed, skipping."
fi

echo -e "\n=== System update script complete at $(date) ===\n"
sleep 1
