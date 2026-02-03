#!/usr/bin/env bash

# Test for the Disk Listing Utility module
# Follows the simple test structure from docs/DEVELOPMENT.md

# Source the module
MODULE_FILE="$(dirname "$0")/../modules/disk.sh"

if [[ -f "$MODULE_FILE" ]]; then
    source "$MODULE_FILE"
else
    echo "✗ Error: Module file not found at $MODULE_FILE"
    exit 1
fi

# Test disk_help
test_disk_help() {
    echo "Running test_disk_help..."
    local result
    result=$(disk_help)
    
    if echo "$result" | grep -q "Disk Management Module"; then
        echo "✓ test_disk_help passed"
        return 0
    else
        echo "✗ test_disk_help failed"
        return 1
    fi
}

# Test disk_list (basic command existence check)
test_disk_list_execution() {
    echo "Running test_disk_list_execution..."
    # We don't want to fail if lsblk fails (e.g. in environments without disks)
    # but we want to check if the function exists and runs.
    if disk_list > /dev/null 2>&1; then
        echo "✓ test_disk_list_execution passed"
        return 0
    else
        echo "✗ test_disk_list_execution failed"
        return 1
    fi
}

# Run tests
errors=0
test_disk_help || ((errors++))
test_disk_list_execution || ((errors++))

if [[ $errors -eq 0 ]]; then
    echo "---------------------------"
    echo "All disk tests passed! ($errors errors)"
    exit 0
else
    echo "---------------------------"
    echo "$errors test(s) failed."
    exit 1
fi
