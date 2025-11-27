# UDM-IPTV Auto-Installation Script

This script automatically installs and maintains [udm-iptv](https://github.com/fabianishere/udm-iptv) on UniFi Dream Machine SE and UDM Max devices, ensuring the service persists across reboots and firmware updates.

## Features

- **Automatic Installation**: Installs udm-iptv on first run
- **Persistent Boot Script**: Creates a boot script that survives reboots and firmware updates
- **Configuration Backup**: Automatically backs up your configuration to `/data` (persistent storage)
- **Auto-Restore**: Restores configuration after reboots
- **Smart Detection**: Only reinstalls when necessary

## How It Works

UniFi Dream Machines reset parts of the filesystem on reboot and firmware updates. This script:

1. Installs udm-iptv normally
2. Creates a boot script in `/data/on_boot.d/` (which persists across reboots)
3. Backs up your configuration to `/data/` (persistent storage)
4. On each boot, the boot script checks if udm-iptv is installed and reinstalls if needed
5. Restores your configuration automatically

## Installation

### Prerequisites

- UniFi Dream Machine SE or UDM Max
- SSH access enabled
- Internet connection

### Steps

1. **SSH into your UDM**:
   ```bash
   ssh root@<your-udm-ip>
   ```

2. **Enter UniFi OS shell**:
   ```bash
   unifi-os shell
   ```

3. **Download and run the auto-install script**:
   ```bash
   curl -sS -L -o /tmp/udm-iptv-autoinstall.sh https://raw.githubusercontent.com/svdleer/kpn-iptv-reinstall/main/udm-iptv-autoinstall.sh
   chmod +x /tmp/udm-iptv-autoinstall.sh
   /tmp/udm-iptv-autoinstall.sh
   ```

4. **Configure udm-iptv** (if first install):
   ```bash
   udm-iptv reconfigure
   ```

5. **Backup your configuration**:
   The script automatically backs up to `/data/udm-iptv.conf.backup`, but you can manually backup anytime:
   ```bash
   cp /etc/udm-iptv.conf /data/udm-iptv.conf.backup
   ```

## What Gets Installed

- **udm-iptv service**: The main IPTV service
- **Boot script**: `/data/on_boot.d/20-udm-iptv.sh` - Runs on every boot
- **Configuration backup**: `/data/udm-iptv.conf.backup` - Persistent storage

## Testing the Auto-Install

After installation, you can test by rebooting your UDM:

```bash
reboot
```

After reboot, check if udm-iptv is running:

```bash
unifi-os shell
systemctl status udm-iptv
```

Check the boot script logs:

```bash
journalctl -t udm-iptv | tail -20
```

## Manual Operations

### Reconfigure udm-iptv
```bash
udm-iptv reconfigure
# Then backup the new configuration
cp /etc/udm-iptv.conf /data/udm-iptv.conf.backup
```

### Check Service Status
```bash
systemctl status udm-iptv
```

### View Logs
```bash
# Service logs
journalctl -u udm-iptv -f

# Boot script logs
journalctl -t udm-iptv
```

### Check Persistence Status
```bash
# Download and run the check script
curl -sS -L -o /tmp/check-persistence.sh https://raw.githubusercontent.com/svdleer/kpn-iptv-reinstall/main/check-persistence.sh
chmod +x /tmp/check-persistence.sh
/tmp/check-persistence.sh
```

### Manually Trigger Boot Script
```bash
/data/on_boot.d/20-udm-iptv.sh
```

### Remove Auto-Install
```bash
# Stop and disable service
systemctl stop udm-iptv
systemctl disable udm-iptv

# Remove boot script
rm /data/on_boot.d/20-udm-iptv.sh

# Remove backups
rm /data/udm-iptv.conf.backup

# Uninstall package
apt-get remove udm-iptv
```

## Persistence Check Script

The `check-persistence.sh` script verifies your installation:

```bash
curl -sS -L https://raw.githubusercontent.com/svdleer/kpn-iptv-reinstall/main/check-persistence.sh | sh
```

This script checks:
- ✓ Boot script exists and is executable
- ✓ Configuration backup exists in persistent storage
- ✓ Package is installed
- ✓ Service is running
- ✓ Configuration files match
- ✓ Recent boot logs

Run this after installation or after a reboot to verify everything is working correctly.

## Troubleshooting

### Service not starting after reboot

1. **Run the persistence check script first**:
   ```bash
   curl -sS -L https://raw.githubusercontent.com/svdleer/kpn-iptv-reinstall/main/check-persistence.sh | sh
   ```

2. Check if boot script ran:
   ```bash
   journalctl -t udm-iptv | tail -20
   ```

2. Check if configuration exists:
   ```bash
   ls -la /etc/udm-iptv.conf
   ls -la /data/udm-iptv.conf.backup
   ```

3. Manually run boot script:
   ```bash
   /data/on_boot.d/20-udm-iptv.sh
   ```

### Configuration not restored

1. Check if backup exists:
   ```bash
   cat /data/udm-iptv.conf.backup
   ```

2. Manually restore:
   ```bash
   cp /data/udm-iptv.conf.backup /etc/udm-iptv.conf
   systemctl restart udm-iptv
   ```

### Boot script not executing

1. Verify boot script is executable:
   ```bash
   ls -la /data/on_boot.d/20-udm-iptv.sh
   ```

2. Make it executable if needed:
   ```bash
   chmod +x /data/on_boot.d/20-udm-iptv.sh
   ```

## Notes

- The `/data` partition persists across reboots and firmware updates
- Always backup your configuration after making changes
- The boot script uses non-interactive installation (DEBIAN_FRONTEND=noninteractive)
- Boot scripts in `/data/on_boot.d/` are executed in alphabetical order

## Author

Silvester van der Leer

## Credits

Based on the original [udm-iptv](https://github.com/fabianishere/udm-iptv) project by Fabian Mastenbroek.

## License

GPL-2.0 (same as udm-iptv)
