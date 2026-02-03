#!/usr/bin/env bash

################################################################################
# Disk Module
# 
# Description: Module for disk management and listing
# Commands: list, help
################################################################################

set -euo pipefail

# Module help
disk_help() {
    cat << EOF
Disk Management Module

Usage: lsm disk <command> [options]

Commands:
  list        - List all attached disks and partitions
  help        - Show this help message

Options:
  -h, --help  Show this help message

Examples:
  lsm disk list
  lsm disk help

EOF
}

# List disks and partitions
disk_list() {
    echo "Listing attached disks and partitions..."
    echo "------------------------------------------------------------"
    
    # Check if lsblk is installed
    if ! command -v lsblk &> /dev/null; then
        echo "Error: lsblk is not installed. Please install 'util-linux' package." >&2
        return 1
    fi

    # Execute lsblk with specified columns
    # NAME: device name
    # SIZE: size of the device
    # TYPE: device type (disk, part, rom, etc.)
    # MOUNTPOINT: where the device is mounted
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
}

# Main module function (dispatcher compatibility)
disk_main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        list)
            disk_list "$@"
            ;;
        help|-h|--help)
            disk_help
            ;;
        *)
            echo "Unknown command: $command"
            disk_help
            exit 1
            ;;
    esac
}
