#!/bin/sh
#
# Auto-installation script for udm-iptv on UniFi Dream Machine SE/UDM Max
# This script installs udm-iptv and sets up automatic reinstallation after reboots
#
# Copyright (C) 2024 Silvester van der Leer
# Based on the original udm-iptv installation script by Fabian Mastenbroek
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

set -e

UDM_IPTV_VERSION=3.0.6
BOOT_SCRIPT_DIR="/data/on_boot.d"
BOOT_SCRIPT_PATH="${BOOT_SCRIPT_DIR}/20-udm-iptv.sh"
CONFIG_BACKUP="/data/udm-iptv.conf.backup"

# Check if running in UniFi OS
if command -v unifi-os > /dev/null 2>&1; then
    echo "error: You need to be in UniFi OS to run the installer."
    echo "Please run the following command to enter UniFi OS:"
    echo
    printf "\tunifi-os shell\n"
    exit 1
fi

# Function to install udm-iptv
install_udm_iptv() {
    echo "Installing udm-iptv version ${UDM_IPTV_VERSION}..."
    
    dest=$(mktemp -d)
    
    echo "Downloading packages..."
    
    # Download udm-iptv package
    curl -sS -o "$dest/udm-iptv.deb" -L \
        "https://github.com/fabianishere/udm-iptv/releases/download/v$UDM_IPTV_VERSION/udm-iptv_${UDM_IPTV_VERSION}_all.deb"
    
    # Fix permissions on the packages
    chown _apt:root "$dest/udm-iptv.deb"
    
    echo "Installing packages..."
    
    # Update APT sources (best effort)
    apt-get update 2>&1 1>/dev/null || true
    
    # Install dialog package for interactive install
    apt-get install -q -y dialog 2>&1 1>/dev/null || echo "Failed to install dialog... Using readline frontend"
    
    # Install udm-iptv
    apt-get install -o Acquire::AllowUnsizedPackages=1 -q -y "$dest/udm-iptv.deb"
    
    # Delete downloaded packages
    rm -rf "$dest"
    
    echo "udm-iptv installed successfully."
}

# Function to create boot script
create_boot_script() {
    echo "Creating boot script for automatic installation..."
    
    # Ensure boot script directory exists
    mkdir -p "$BOOT_SCRIPT_DIR"
    
    # Create the boot script
    cat > "$BOOT_SCRIPT_PATH" << 'EOF'
#!/bin/sh
#
# Auto-reinstall udm-iptv after reboot
# This script is executed automatically on boot

UDM_IPTV_VERSION=3.0.6
CONFIG_BACKUP="/data/udm-iptv.conf.backup"

# Log function
log() {
    echo "[udm-iptv-autoinstall] $1" | logger -t udm-iptv
    echo "[udm-iptv-autoinstall] $1"
}

log "Starting udm-iptv auto-installation..."

# Check if udm-iptv is already installed
if dpkg -l | grep -q udm-iptv; then
    log "udm-iptv is already installed, checking configuration..."
    
    # Restore configuration if backup exists and current config doesn't
    if [ -f "$CONFIG_BACKUP" ] && [ ! -f /etc/udm-iptv.conf ]; then
        log "Restoring configuration from backup..."
        cp "$CONFIG_BACKUP" /etc/udm-iptv.conf
    fi
    
    # Restart service if needed
    if systemctl is-active --quiet udm-iptv; then
        log "udm-iptv service is already running."
    else
        log "Starting udm-iptv service..."
        systemctl start udm-iptv || log "Failed to start udm-iptv service"
    fi
    
    exit 0
fi

log "udm-iptv not found, installing..."

dest=$(mktemp -d)

# Download udm-iptv package
log "Downloading udm-iptv version ${UDM_IPTV_VERSION}..."
if ! curl -sS -o "$dest/udm-iptv.deb" -L \
    "https://github.com/fabianishere/udm-iptv/releases/download/v$UDM_IPTV_VERSION/udm-iptv_${UDM_IPTV_VERSION}_all.deb"; then
    log "ERROR: Failed to download udm-iptv package"
    rm -rf "$dest"
    exit 1
fi

# Fix permissions on the packages
chown _apt:root "$dest/udm-iptv.deb"

# Update APT sources (best effort)
log "Updating APT sources..."
apt-get update 2>&1 1>/dev/null || true

# Install dialog package (non-interactive)
log "Installing dependencies..."
DEBIAN_FRONTEND=noninteractive apt-get install -q -y dialog 2>&1 1>/dev/null || true

# Install udm-iptv (non-interactive)
log "Installing udm-iptv package..."
if DEBIAN_FRONTEND=noninteractive apt-get install -o Acquire::AllowUnsizedPackages=1 -q -y "$dest/udm-iptv.deb"; then
    log "udm-iptv installed successfully"
    
    # Restore configuration if backup exists
    if [ -f "$CONFIG_BACKUP" ]; then
        log "Restoring configuration from backup..."
        cp "$CONFIG_BACKUP" /etc/udm-iptv.conf
        
        # Start the service
        log "Starting udm-iptv service..."
        systemctl start udm-iptv || log "Failed to start udm-iptv service"
    else
        log "No configuration backup found. Please run: udm-iptv reconfigure"
    fi
else
    log "ERROR: Failed to install udm-iptv package"
fi

# Delete downloaded packages
rm -rf "$dest"

log "Auto-installation complete."
EOF
    
    # Make boot script executable
    chmod +x "$BOOT_SCRIPT_PATH"
    
    echo "Boot script created at: $BOOT_SCRIPT_PATH"
}

# Function to backup configuration
backup_configuration() {
    if [ -f /etc/udm-iptv.conf ]; then
        echo "Backing up configuration to persistent storage..."
        cp /etc/udm-iptv.conf "$CONFIG_BACKUP"
        echo "Configuration backed up to: $CONFIG_BACKUP"
    fi
}

# Main installation flow
echo "================================================"
echo "  UDM-IPTV Auto-Installation Script"
echo "  Version: ${UDM_IPTV_VERSION}"
echo "================================================"
echo

# Install udm-iptv
install_udm_iptv

# Create boot script for auto-installation after reboots
create_boot_script

# Backup configuration
backup_configuration

echo
echo "================================================"
echo "Installation successful!"
echo "================================================"
echo
echo "Your configuration is at: /etc/udm-iptv.conf"
echo "Configuration backup: $CONFIG_BACKUP"
echo "Boot script: $BOOT_SCRIPT_PATH"
echo
echo "The service will automatically reinstall after each reboot."
echo
echo "Useful commands:"
echo "  - Reconfigure: udm-iptv reconfigure"
echo "  - Check status: systemctl status udm-iptv"
echo "  - View logs: journalctl -u udm-iptv -f"
echo "  - Backup config: cp /etc/udm-iptv.conf $CONFIG_BACKUP"
echo
