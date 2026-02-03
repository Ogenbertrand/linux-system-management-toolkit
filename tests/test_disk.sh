#!/usr/bin/env bash

# Tests for the Disk module (list, usage, help)
# Follows the simple test structure from docs/DEVELOPMENT.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
MODULE_FILE="${BASE_DIR}/modules/disk.sh"

# So disk_load_config finds config when disk_usage runs
export BASE_DIR

if [[ -f "$MODULE_FILE" ]]; then
    # shellcheck source=/dev/null
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

    if echo "$result" | grep -q "Disk Management Module" && echo "$result" | grep -q "usage"; then
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

# Test disk_usage
test_disk_usage_output() {
    echo "Running test_disk_usage_output..."
    local result
    result=$(disk_usage 2>&1) || true
    if echo "$result" | grep -q "FILESYSTEM" && \
       echo "$result" | grep -q "TOTAL" && \
       echo "$result" | grep -q "USED" && \
       echo "$result" | grep -q "AVAILABLE" && \
       echo "$result" | grep -q "USE%"; then
        echo "✓ test_disk_usage_output passed"
        return 0
    else
        echo "✗ test_disk_usage_output failed (missing expected columns)"
        return 1
    fi
}

# Test disk_usage
test_disk_usage_exit() {
    echo "Running test_disk_usage_exit..."
    local result
    result=$(disk_usage 2>&1)
    local code=$?
    if [[ $code -eq 0 ]] && [[ "$result" =~ [0-9]+[GgMmKk]? ]]; then
        echo "✓ test_disk_usage_exit passed"
        return 0
    else
        echo "✗ test_disk_usage_exit failed (exit=$code or no size data)"
        return 1
    fi
}

# Run tests
errors=0
test_disk_help || ((errors++))
test_disk_list_execution || ((errors++))
test_disk_usage_output || ((errors++))
test_disk_usage_exit || ((errors++))

if [[ $errors -eq 0 ]]; then
    echo "---------------------------"
    echo "All disk tests passed!"
    exit 0
else
    echo "---------------------------"
    echo "$errors test(s) failed."
    exit 1
fi
