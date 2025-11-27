#!/bin/sh
#
# Persistence Check Script for udm-iptv auto-installation
# This script verifies that all components are correctly installed and configured
#
# Copyright (C) 2024 Silvester van der Leer
# Based on the original udm-iptv installation script by Fabian Mastenbroek
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Configuration
BOOT_SCRIPT_PATH="/data/on_boot.d/20-udm-iptv.sh"
CONFIG_BACKUP="/data/udm-iptv.conf.backup"
CONFIG_ACTIVE="/etc/udm-iptv.conf"

# Helper functions
print_header() {
    echo "${BLUE}================================================${NC}"
    echo "${BLUE}  UDM-IPTV Persistence Check${NC}"
    echo "${BLUE}================================================${NC}"
    echo
}

print_check() {
    printf "%-50s" "$1"
}

print_pass() {
    echo "${GREEN}[PASS]${NC}"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
}

print_fail() {
    echo "${RED}[FAIL]${NC}"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
}

print_warn() {
    echo "${YELLOW}[WARN]${NC}"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
}

print_info() {
    echo "${BLUE}ℹ${NC} $1"
}

print_summary() {
    echo
    echo "${BLUE}================================================${NC}"
    echo "${BLUE}  Summary${NC}"
    echo "${BLUE}================================================${NC}"
    echo "Checks passed:  ${GREEN}${CHECKS_PASSED}${NC}"
    echo "Checks failed:  ${RED}${CHECKS_FAILED}${NC}"
    echo "Warnings:       ${YELLOW}${CHECKS_WARNING}${NC}"
    echo
    
    if [ $CHECKS_FAILED -eq 0 ] && [ $CHECKS_WARNING -eq 0 ]; then
        echo "${GREEN}✓ All checks passed! Your installation is persistent.${NC}"
        return 0
    elif [ $CHECKS_FAILED -eq 0 ]; then
        echo "${YELLOW}⚠ Some warnings detected. Review above.${NC}"
        return 0
    else
        echo "${RED}✗ Some checks failed. Please review and fix issues.${NC}"
        return 1
    fi
}

# Check functions
check_unifi_os() {
    print_check "Running in UniFi OS environment"
    if command -v unifi-os > /dev/null 2>&1; then
        print_fail
        print_info "You need to run this from within UniFi OS shell"
        print_info "Run: unifi-os shell"
        return 1
    else
        print_pass
    fi
}

check_boot_script_exists() {
    print_check "Boot script exists"
    if [ -f "$BOOT_SCRIPT_PATH" ]; then
        print_pass
    else
        print_fail
        print_info "Boot script not found at: $BOOT_SCRIPT_PATH"
        print_info "Run the installation script to create it"
    fi
}

check_boot_script_executable() {
    print_check "Boot script is executable"
    if [ -x "$BOOT_SCRIPT_PATH" ]; then
        print_pass
    else
        print_fail
        print_info "Boot script is not executable"
        print_info "Fix with: chmod +x $BOOT_SCRIPT_PATH"
    fi
}

check_boot_script_content() {
    print_check "Boot script contains valid content"
    if [ -f "$BOOT_SCRIPT_PATH" ] && grep -q "udm-iptv" "$BOOT_SCRIPT_PATH"; then
        print_pass
    else
        print_fail
        print_info "Boot script appears to be invalid or empty"
    fi
}

check_config_backup_exists() {
    print_check "Configuration backup exists"
    if [ -f "$CONFIG_BACKUP" ]; then
        print_pass
    else
        print_warn
        print_info "No configuration backup found at: $CONFIG_BACKUP"
        print_info "This is normal for first install before configuration"
        print_info "After configuring, run: cp $CONFIG_ACTIVE $CONFIG_BACKUP"
    fi
}

check_config_active() {
    print_check "Active configuration exists"
    if [ -f "$CONFIG_ACTIVE" ]; then
        print_pass
    else
        print_warn
        print_info "No active configuration found"
        print_info "Run: udm-iptv reconfigure"
    fi
}

check_igmpproxy_installed() {
    print_check "igmpproxy is installed"
    if command -v igmpproxy > /dev/null 2>&1; then
        print_pass
    else
        print_fail
        print_info "igmpproxy is not installed"
        print_info "Install with: apt-get install igmpproxy"
    fi
}

check_package_installed() {
    print_check "udm-iptv package is installed"
    if dpkg -l | grep -q udm-iptv; then
        print_pass
    else
        print_fail
        print_info "udm-iptv package is not installed"
        print_info "Run the installation script"
    fi
}

check_service_exists() {
    print_check "udm-iptv service exists"
    if systemctl list-unit-files | grep -q udm-iptv; then
        print_pass
    else
        print_fail
        print_info "udm-iptv service not found"
    fi
}

check_service_enabled() {
    print_check "udm-iptv service is enabled"
    if systemctl is-enabled --quiet udm-iptv 2>/dev/null; then
        print_pass
    else
        print_warn
        print_info "Service is not enabled"
        print_info "This is normal - the boot script will start it"
    fi
}

check_service_active() {
    print_check "udm-iptv service is running"
    if systemctl is-active --quiet udm-iptv; then
        print_pass
    else
        print_warn
        print_info "Service is not currently running"
        print_info "Start with: systemctl start udm-iptv"
    fi
}

check_data_partition() {
    print_check "/data directory exists and is writable"
    if [ -d /data ] && [ -w /data ]; then
        print_pass
    else
        print_fail
        if [ ! -d /data ]; then
            print_info "/data directory does not exist - this is critical!"
            print_info "Create with: mkdir -p /data"
        else
            print_info "/data directory is not writable"
            print_info "Fix with: chmod 755 /data"
        fi
    fi
}

check_on_boot_dir() {
    print_check "/data/on_boot.d directory exists"
    if [ -d "/data/on_boot.d" ]; then
        print_pass
    else
        print_fail
        print_info "Boot script directory is missing"
        print_info "Install on-boot-script with:"
        print_info "  curl -fsL \"https://raw.githubusercontent.com/unifi-utilities/unifios-utilities/HEAD/on-boot-script-2.x/remote_install.sh\" | /bin/bash"
    fi
}

check_udm_boot_service() {
    print_check "udm-boot service is installed"
    if systemctl list-unit-files | grep -q udm-boot; then
        print_pass
    else
        print_fail
        print_info "on-boot-script service not found"
        print_info "This is required for boot persistence"
        print_info "Install with:"
        print_info "  curl -fsL \"https://raw.githubusercontent.com/unifi-utilities/unifios-utilities/HEAD/on-boot-script-2.x/remote_install.sh\" | /bin/bash"
    fi
}

check_udm_boot_enabled() {
    print_check "udm-boot service is enabled"
    if systemctl is-enabled --quiet udm-boot 2>/dev/null; then
        print_pass
    else
        print_warn
        print_info "udm-boot service is not enabled"
        print_info "Enable with: systemctl enable udm-boot"
    fi
}

check_udm_boot_active() {
    print_check "udm-boot service is running"
    if systemctl is-active --quiet udm-boot 2>/dev/null; then
        print_pass
    else
        print_warn
        print_info "udm-boot service is not running"
        print_info "Start with: systemctl start udm-boot"
    fi
}

check_config_matches() {
    print_check "Active config matches backup"
    if [ -f "$CONFIG_ACTIVE" ] && [ -f "$CONFIG_BACKUP" ]; then
        if cmp -s "$CONFIG_ACTIVE" "$CONFIG_BACKUP"; then
            print_pass
        else
            print_warn
            print_info "Configuration files differ"
            print_info "Update backup with: cp $CONFIG_ACTIVE $CONFIG_BACKUP"
        fi
    else
        print_warn
        print_info "Cannot compare - one or both config files missing"
    fi
}

show_service_status() {
    echo
    echo "${BLUE}================================================${NC}"
    echo "${BLUE}  Service Status${NC}"
    echo "${BLUE}================================================${NC}"
    systemctl status udm-iptv --no-pager || echo "Service not found"
}

show_recent_logs() {
    echo
    echo "${BLUE}================================================${NC}"
    echo "${BLUE}  Recent Boot Script Logs${NC}"
    echo "${BLUE}================================================${NC}"
    journalctl -t udm-iptv --no-pager -n 20 || echo "No logs found"
}

show_file_info() {
    echo
    echo "${BLUE}================================================${NC}"
    echo "${BLUE}  File Information${NC}"
    echo "${BLUE}================================================${NC}"
    echo
    echo "Boot script:"
    ls -lh "$BOOT_SCRIPT_PATH" 2>/dev/null || echo "  Not found"
    echo
    echo "Configuration backup:"
    ls -lh "$CONFIG_BACKUP" 2>/dev/null || echo "  Not found"
    echo
    echo "Active configuration:"
    ls -lh "$CONFIG_ACTIVE" 2>/dev/null || echo "  Not found"
}

# Main execution
main() {
    print_header
    
    # Run all checks
    check_unifi_os
    echo
    check_data_partition
    check_on_boot_dir
    echo
    check_udm_boot_service
    check_udm_boot_enabled
    check_udm_boot_active
    echo
    check_boot_script_exists
    check_boot_script_executable
    check_boot_script_content
    echo
    check_config_backup_exists
    check_config_active
    check_config_matches
    echo
    check_igmpproxy_installed
    check_package_installed
    check_service_exists
    check_service_enabled
    check_service_active
    
    # Show additional information
    show_file_info
    show_service_status
    show_recent_logs
    
    # Print summary and exit with appropriate code
    print_summary
    exit $?
}

# Run main function
main
