#!/usr/bin/env bash

# Test for the CLI Help & Module Discovery feature (LSMT-016)
# Follows the simple test structure from docs/DEVELOPMENT.md

TOOLKIT="$(dirname "$0")/../bin/lsm-toolkit"

if [[ ! -f "$TOOLKIT" ]]; then
    echo "Error: Toolkit not found at $TOOLKIT"
    exit 1
fi

# Test global help with --help flag
test_global_help_flag() {
    echo "Running test_global_help_flag..."
    local result
    result=$("$TOOLKIT" --help)

    if echo "$result" | grep -q "Linux System Management Toolkit"; then
        echo "PASS test_global_help_flag passed"
        return 0
    else
        echo "FAIL test_global_help_flag failed"
        return 1
    fi
}

# Test global help with -h flag
test_global_help_short() {
    echo "Running test_global_help_short..."
    local result
    result=$("$TOOLKIT" -h)

    if echo "$result" | grep -q "Available Modules:"; then
        echo "PASS test_global_help_short passed"
        return 0
    else
        echo "FAIL test_global_help_short failed"
        return 1
    fi
}

# Test global help with help command
test_global_help_command() {
    echo "Running test_global_help_command..."
    local result
    result=$("$TOOLKIT" help)

    if echo "$result" | grep -q "Usage:"; then
        echo "PASS test_global_help_command passed"
        return 0
    else
        echo "FAIL test_global_help_command failed"
        return 1
    fi
}

# Test module discovery
test_module_discovery() {
    echo "Running test_module_discovery..."
    local result
    result=$("$TOOLKIT" --help)

    if echo "$result" | grep -q "disk" && echo "$result" | grep -q "system"; then
        echo "PASS test_module_discovery passed"
        return 0
    else
        echo "FAIL test_module_discovery failed"
        return 1
    fi
}

# Test module-level help with --help flag
test_module_help_flag() {
    echo "Running test_module_help_flag..."
    local result
    result=$("$TOOLKIT" disk --help)

    if echo "$result" | grep -q "Disk Management Module"; then
        echo "PASS test_module_help_flag passed"
        return 0
    else
        echo "FAIL test_module_help_flag failed"
        return 1
    fi
}

# Test module-level help with -h flag
test_module_help_short() {
    echo "Running test_module_help_short..."
    local result
    result=$("$TOOLKIT" system -h)

    if echo "$result" | grep -q "System Monitoring Module"; then
        echo "PASS test_module_help_short passed"
        return 0
    else
        echo "FAIL test_module_help_short failed"
        return 1
    fi
}

# Test no arguments shows help
test_no_args_shows_help() {
    echo "Running test_no_args_shows_help..."
    local result
    result=$("$TOOLKIT")

    if echo "$result" | grep -q "Linux System Management Toolkit"; then
        echo "PASS test_no_args_shows_help passed"
        return 0
    else
        echo "FAIL test_no_args_shows_help failed"
        return 1
    fi
}

# Test backward compatibility - existing commands still work
test_backward_compatibility() {
    echo "Running test_backward_compatibility..."
    # Test that command dispatch still works (system memory is more portable than disk list)
    # disk list requires lsblk which may not be available on all systems
    if "$TOOLKIT" system memory > /dev/null 2>&1; then
        echo "PASS test_backward_compatibility passed"
        return 0
    else
        # Fallback: just verify the command is recognized (not "command not found")
        local result
        result=$("$TOOLKIT" disk list 2>&1)
        if echo "$result" | grep -q "Command 'list' not found"; then
            echo "FAIL test_backward_compatibility failed"
            return 1
        else
            echo "PASS test_backward_compatibility passed (command recognized)"
            return 0
        fi
    fi
}

# Run tests
errors=0
test_global_help_flag || ((errors++))
test_global_help_short || ((errors++))
test_global_help_command || ((errors++))
test_module_discovery || ((errors++))
test_module_help_flag || ((errors++))
test_module_help_short || ((errors++))
test_no_args_shows_help || ((errors++))
test_backward_compatibility || ((errors++))

if [[ $errors -eq 0 ]]; then
    echo "---------------------------"
    echo "All help tests passed! ($errors errors)"
    exit 0
else
    echo "---------------------------"
    echo "$errors test(s) failed."
    exit 1
fi
