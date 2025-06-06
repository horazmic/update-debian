#!/bin/bash
set -e

error_handler() {
    echo "Error occurred in script at line: $1"
    exit 1
}
trap 'error_handler $LINENO' ERR

sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt clean
sudo flatpak update -y

echo "System update complete."