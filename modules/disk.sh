#!/bin/bash

# Check SMART health status of a disk
check_disk_health() {
    local disk="$1"
    local device_type=""
    local disk_kind="sata"

    echo "Checking SMART health for disk: $disk"

    # Ensure smartctl exists
    if ! command -v smartctl >/dev/null 2>&1; then
        echo "  Error: smartctl not found. Install smartmontools."
        return 1
    fi

    # Detect NVMe disks
    if [[ "$disk" == /dev/nvme* ]]; then
        device_type="-d nvme"
        disk_kind="nvme"
    fi

    # Check SMART support
    if ! smartctl -i $device_type "$disk" >/dev/null 2>&1; then
        echo "  SMART not supported for this disk."
        return 0
    fi

    # Overall health status
    health_status=$(smartctl -H $device_type "$disk" \
        | awk -F: '/SMART overall-health/ {print $2}' | xargs)

    if [[ "$health_status" == "PASSED" ]]; then
        echo "  Overall Health: PASSED"
    elif [[ "$health_status" == "FAILED" ]]; then
        echo "  Overall Health: FAILED"
    else
        echo "  Overall Health: UNKNOWN"
    fi

    # SMART attributes
    echo "  SMART Attributes:"

    if [[ "$disk_kind" == "nvme" ]]; then
        smartctl -a $device_type "$disk" | grep -E \
        "Critical Warning|Temperature:|Available Spare|Percentage Used|Power On Hours|Data Units Written"
    else
        smartctl -A "$disk" | grep -E \
        "Power_On_Hours|Temperature_Celsius|Reallocated_Sector_Ct|Current_Pending_Sector|Offline_Uncorrectable"
    fi

    echo
}

main() {
    echo "--- Disk Health Monitoring ---"

    disks=$(lsblk -dno KNAME,TYPE | awk '$2 == "disk" {print "/dev/"$1}')

    if [[ -z "$disks" ]]; then
        echo "No physical disks found."
        exit 1
    fi

    for disk in $disks; do
        check_disk_health "$disk"
    done

    echo "--- Monitoring Complete ---"
}

main
