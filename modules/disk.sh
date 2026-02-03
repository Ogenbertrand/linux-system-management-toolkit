#!/usr/bin/env bash

################################################################################
# Disk Module (LSMT-004)
#
# Description: Module for disk management, listing, usage reporting, and health.
# Commands: list, usage, health, help
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

# --- Health Monitoring Logic (Your Original Code) ---

disk_health() {
    echo "--- Disk Health Monitoring ---"

    # Detect physical disks
    local disks
    disks=$(lsblk -dno KNAME,TYPE | awk '$2 == "disk" {print "/dev/"$1}')

    if [[ -z "$disks" ]]; then
        echo "No physical disks found."
        return 1
    fi

    # Ensure smartctl exists
    if ! command -v smartctl >/dev/null 2>&1; then
        echo "  Error: smartctl not found. Install smartmontools."
        return 1
    fi

    for disk in $disks; do
        local device_type=""
        local disk_kind="sata"

        echo "Checking SMART health for disk: $disk"

        # Detect NVMe disks
        if [[ "$disk" == /dev/nvme* ]]; then
            device_type="-d nvme"
            disk_kind="nvme"
        fi

        # Check SMART support
        if ! sudo smartctl -i $device_type "$disk" >/dev/null 2>&1; then
            echo "  SMART not supported for this disk."
            continue
        fi

        # Overall health status
        local health_status
        health_status=$(sudo smartctl -H $device_type "$disk" \
            | awk -F: '/SMART overall-health/ || /test result/ {print $2}' | xargs)

        echo "  Overall Health: ${health_status:-UNKNOWN}"

        # SMART attributes
        echo "  SMART Attributes:"
        if [[ "$disk_kind" == "nvme" ]]; then
            sudo smartctl -a $device_type "$disk" | grep -E \
            "Critical Warning|Temperature:|Available Spare|Percentage Used|Power On Hours|Data Units Written"
        else
            sudo smartctl -A "$disk" | grep -E \
            "Power_On_Hours|Temperature_Celsius|Reallocated_Sector_Ct|Current_Pending_Sector|Offline_Uncorrectable"
        fi
        echo
    done

    echo "--- Monitoring Complete ---"
}

# --- Standard Toolkit Functions ---

disk_help() {
    cat << EOF
Disk Management Module (LSMT-004)

Usage: lsm disk <command> [options]

Commands:
  list        - List all attached disks and partitions
  usage       - Report disk space (total, used, available, use%)
  health      - Check SMART health status of physical disks
  help        - Show this help message

Options:
  -h, --help  Show this help message

Examples:
  lsm disk list
  lsm disk usage
  lsm disk health

EOF
}

disk_list() {
    echo "Listing attached disks and partitions..."
    echo "------------------------------------------------------------"
    if ! command -v lsblk &> /dev/null; then
        echo "Error: lsblk is not installed. Please install 'util-linux' package." >&2
        return 1
    fi
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
}

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
        echo -e "\nThreshold warnings (ALERT_DISK_THRESHOLD=${ALERT_DISK_THRESHOLD}%):$warn_lines"
    fi
}

# --- Main Module Dispatcher ---

disk_main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        list)   disk_list "$@" ;;
        usage)  disk_usage "$@" ;;
        health) disk_health "$@" ;;
        help|-h|--help) disk_help ;;
        *)
            echo "Unknown command: $command"
            disk_help
            exit 1
            ;;
    esac
}

# Execute dispatcher if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    disk_main "$@"
fi