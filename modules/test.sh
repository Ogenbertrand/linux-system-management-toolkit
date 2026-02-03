#!/usr/bin/env bash

# Minimal test module - Integrated with Disk Health Monitor
test_run() {
    echo "-----------------------------------------------"
    echo "LSM Toolkit: Module Loading System is working!"
    echo "-----------------------------------------------"

    echo "Running Module Validation: disk.sh"

    # 1. Check if the disk monitor script exists in the correct folder
    if [[ -f "modules/disk.sh" ]]; then
        echo "[PASS] Logic: disk.sh is present in modules/."
    else
        echo "[FAIL] Logic: disk.sh is missing from modules/."
        return 1
    fi

    # 2. Check if the disk script has execution permissions
    if [[ -x "modules/disk.sh" ]]; then
        echo "[PASS] Permissions: disk.sh is executable."
    else
        echo "[WARN] Permissions: disk.sh is not executable. Run 'chmod +x modules/disk.sh'."
    fi

    # 3. Check for the smartctl dependency (smartmontools)
    if command -v smartctl >/dev/null 2>&1; then
        echo "[PASS] Dependency: smartctl (smartmontools) is installed."
    else
        echo "[FAIL] Dependency: smartctl is missing. Install with 'sudo apt install smartmontools'."
    fi

    echo "-----------------------------------------------"
    echo "Validation Complete."
}