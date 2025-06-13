#!/bin/bash

# --- Input validation ---
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <server_ip> <share_name> <mount_point> <username>"
  exit 1
fi

# --- Variables ---
SERVER_IP="$1"
SHARE_NAME="$2"
MOUNT_POINT="$3"
USERNAME="$4"

SHARE="//${SERVER_IP}/${SHARE_NAME}"
CREDENTIALS_FILE="/etc/samba/creds_${SHARE_NAME}"
FSTAB_LINE="${SHARE}  ${MOUNT_POINT}  cifs  credentials=${CREDENTIALS_FILE},iocharset=utf8,nofail  0  0"

# --- Prompt for SMB password (before sudo) ---
read -s -p "Enter SMB password for user $USERNAME: " PASSWORD
echo

# --- Ensure cifs-utils is installed ---
if ! dpkg -s cifs-utils &> /dev/null; then
  echo "cifs-utils not found. Installing..."
  sudo apt update && sudo apt install -y cifs-utils
else
  echo "cifs-utils already installed."
fi

# --- Create mount point ---
echo "Creating mount point at $MOUNT_POINT..."
sudo mkdir -p "$MOUNT_POINT"

# --- Create credentials file ---
echo "Creating credentials file at $CREDENTIALS_FILE..."
echo "username=$USERNAME" | sudo tee "$CREDENTIALS_FILE" > /dev/null
echo "password=$PASSWORD" | sudo tee -a "$CREDENTIALS_FILE" > /dev/null
sudo chmod 600 "$CREDENTIALS_FILE"

# --- Backup and update /etc/fstab ---
echo "Backing up /etc/fstab..."
sudo cp /etc/fstab /etc/fstab.bak

if ! grep -Fq "$SHARE" /etc/fstab; then
    echo "Adding entry to /etc/fstab..."
    echo "$FSTAB_LINE" | sudo tee -a /etc/fstab
else
    echo "An entry for $SHARE already exists in /etc/fstab."
fi

# --- Reload systemd (optional) ---
echo "Reloading systemd daemon..."
sudo systemctl daemon-reexec

# --- Mount the share ---
echo "Mounting share..."
sudo mount "$MOUNT_POINT"

# --- Done ---
echo "✅ Done. Remote share mounted at $MOUNT_POINT."

