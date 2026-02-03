#!/usr/bin/env bash

################################################################################
# Disk Module
#
# Description: Module for disk management, listing, and usage reporting.
# Commands: list, usage, help
################################################################################

set -euo pipefail

# Load config if available (BASE_DIR set by lsm-toolkit dispatcher)
disk_load_config() {
    local config_file="${BASE_DIR:-.}/config/toolkit.conf"
    if [[ -f "$config_file" ]]; then
        # shellcheck source=/dev/null
        source "$config_file"
    fi
    ALERT_DISK_THRESHOLD="${ALERT_DISK_THRESHOLD:-0}"
}

# Module help
disk_help() {
    cat << EOF
Disk Management Module (LSMT-004)

Usage: lsm disk <command> [options]

Commands:
  list        - List all attached disks and partitions
  usage       - Report disk space (total, used, available, use%) for mounted
                partitions; optional threshold warnings via ALERT_DISK_THRESHOLD
  help        - Show this help message

Options:
  -h, --help  Show this help message

Examples:
  lsm disk list
  lsm disk usage
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

# Report disk space usage for all mounted partitions
disk_usage() {
    disk_load_config

    echo "Disk space usage (mounted partitions)"
    echo "====================================="
    printf "%-24s %10s %10s %10s %6s %s\n" "FILESYSTEM" "TOTAL" "USED" "AVAILABLE" "USE%" "MOUNTED ON"
    printf "%-24s %10s %10s %10s %6s %s\n" "---------" "-----" "----" "---------" "----" "----------"

    local warn_lines=""
    while read -r fs size used avail pct mount_rest; do
        printf "%-24s %10s %10s %10s %6s %s\n" "$fs" "$size" "$used" "$avail" "$pct" "$mount_rest"
        local pct_num="${pct%%%*}"
        if [[ "${ALERT_DISK_THRESHOLD:-0}" -gt 0 ]] && [[ "$pct_num" =~ ^[0-9]+$ ]] && [[ "$pct_num" -ge "${ALERT_DISK_THRESHOLD}" ]]; then
            warn_lines="${warn_lines}\n  WARNING: ${mount_rest} is at ${pct} (threshold: ${ALERT_DISK_THRESHOLD}%)"
        fi
    done < <(df -h -P | tail -n +2)

    if [[ -n "${warn_lines:-}" ]]; then
        echo ""
        echo "Threshold warnings (ALERT_DISK_THRESHOLD=${ALERT_DISK_THRESHOLD}%):"
        printf "%b\n" "$warn_lines"
    fi
}

# Main module function (dispatcher compatibility)
disk_main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        list)
            disk_list "$@"
            ;;
        usage)
            disk_usage "$@"
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
