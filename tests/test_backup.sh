#!/usr/bin/env bash

################################################################################
# Test Suite for Backup Module
################################################################################

# Color codes
readonly C_RST='\033[0m'
readonly C_G='\033[0;32m'
readonly C_R='\033[0;31m'
readonly C_Y='\033[0;33m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
LSM_TOOLKIT="${BASE_DIR}/bin/lsm-toolkit"

# Test setup
setup() {
    # Create temporary test directories
    TEST_DIR="/tmp/lsm-backup-test-$$"
    TEST_SOURCE="${TEST_DIR}/source"
    TEST_BACKUP_DIR="${TEST_DIR}/backups"
    
    mkdir -p "$TEST_SOURCE"
    mkdir -p "$TEST_BACKUP_DIR"
    
    # Create test files
    echo "Test file 1" > "${TEST_SOURCE}/file1.txt"
    echo "Test file 2" > "${TEST_SOURCE}/file2.txt"
    mkdir -p "${TEST_SOURCE}/subdir"
    echo "Nested file" > "${TEST_SOURCE}/subdir/nested.txt"
    
    # Override backup directory for tests
    export BACKUP_DIR="$TEST_BACKUP_DIR"
}

# Test teardown
teardown() {
    # Clean up test directory
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# Assert function
assert() {
    local description="$1"
    local condition="$2"
    
    if eval "$condition"; then
        echo -e "${C_G}✓ PASS${C_RST}: $description"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${C_R}✗ FAIL${C_RST}: $description"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test: backup help command
test_backup_help() {
    echo ""
    echo "Test: Backup help command"
    local output=$("$LSM_TOOLKIT" backup help 2>&1)
    assert "Help command returns content" '[[ -n "$output" ]]'
    assert "Help contains usage information" '[[ "$output" =~ "Usage:" ]]'
    assert "Help mentions create command" '[[ "$output" =~ "create" ]]'
    assert "Help mentions restore command" '[[ "$output" =~ "restore" ]]'
}

# Test: backup create with valid source
test_backup_create_valid() {
    echo ""
    echo "Test: Backup create with valid source"
    setup
    
    cd "$TEST_DIR" || exit 1
    local output=$("$LSM_TOOLKIT" backup create "$TEST_SOURCE" 2>&1)
    
    assert "Create command succeeds" '[[ $? -eq 0 ]]'
    assert "Backup file is created" '[[ -n "$(find "$TEST_BACKUP_DIR" -name "source_*.tar.gz" 2>/dev/null)" ]]'
    assert "Output contains success message" '[[ "$output" =~ "successfully" ]]'
    
    teardown
}

# Test: backup create with non-existent source
test_backup_create_invalid() {
    echo ""
    echo "Test: Backup create with non-existent source"
    setup
    
    cd "$TEST_DIR" || exit 1
    local output=$("$LSM_TOOLKIT" backup create "/nonexistent/path" 2>&1)
    local exit_code=$?
    
    assert "Create command fails with non-existent path" '[[ $exit_code -ne 0 ]]'
    assert "Error message is shown" '[[ "$output" =~ "Error" || "$output" =~ "does not exist" ]]'
    
    teardown
}

# Test: backup list
test_backup_list() {
    echo ""
    echo "Test: Backup list command"
    setup
    
    cd "$TEST_DIR" || exit 1
    # Create a backup first
    "$LSM_TOOLKIT" backup create "$TEST_SOURCE" > /dev/null 2>&1
    
    local output=$("$LSM_TOOLKIT" backup list 2>&1)
    
    assert "List command succeeds" '[[ $? -eq 0 ]]'
    assert "List shows backup files" '[[ "$output" =~ "source_" ]]'
    
    teardown
}

# Test: backup restore with valid backup
test_backup_restore_valid() {
    echo ""
    echo "Test: Backup restore with valid backup"
    setup
    
    cd "$TEST_DIR" || exit 1
    
    # Create a backup
    "$LSM_TOOLKIT" backup create "$TEST_SOURCE" > /dev/null 2>&1
    
    # Find the backup file
    local backup_file=$(find "$TEST_BACKUP_DIR" -name "source_*.tar.gz" | head -n 1)
    
    # Remove original source
    rm -rf "$TEST_SOURCE"
    
    # Restore the backup
    local output=$("$LSM_TOOLKIT" backup restore "$backup_file" "$TEST_DIR" 2>&1)
    
    assert "Restore command succeeds" '[[ $? -eq 0 ]]'
    assert "Source directory is restored" '[[ -d "$TEST_SOURCE" ]]'
    assert "File1 is restored" '[[ -f "${TEST_SOURCE}/file1.txt" ]]'
    assert "File2 is restored" '[[ -f "${TEST_SOURCE}/file2.txt" ]]'
    assert "Nested file is restored" '[[ -f "${TEST_SOURCE}/subdir/nested.txt" ]]'
    assert "File content is correct" '[[ "$(cat "${TEST_SOURCE}/file1.txt")" == "Test file 1" ]]'
    
    teardown
}

# Test: backup restore with non-existent file
test_backup_restore_missing() {
    echo ""
    echo "Test: Backup restore with non-existent file"
    setup
    
    cd "$TEST_DIR" || exit 1
    local output=$("$LSM_TOOLKIT" backup restore "/nonexistent/backup.tar.gz" 2>&1)
    local exit_code=$?
    
    assert "Restore command fails with missing file" '[[ $exit_code -ne 0 ]]'
    assert "Error message is shown" '[[ "$output" =~ "Error" || "$output" =~ "does not exist" ]]'
    
    teardown
}

# Test: backup restore with corrupted file
test_backup_restore_corrupted() {
    echo ""
    echo "Test: Backup restore with corrupted file"
    setup
    
    cd "$TEST_DIR" || exit 1
    
    # Create a fake corrupted backup file
    local fake_backup="${TEST_BACKUP_DIR}/corrupted.tar.gz"
    echo "This is not a valid tar archive" > "$fake_backup"
    
    local output=$("$LSM_TOOLKIT" backup restore "$fake_backup" 2>&1)
    local exit_code=$?
    
    assert "Restore command fails with corrupted file" '[[ $exit_code -ne 0 ]]'
    assert "Error message mentions corruption" '[[ "$output" =~ "Error" || "$output" =~ "corrupted" || "$output" =~ "valid" ]]'
    
    teardown
}

# Main test runner
main() {
    echo -e "${C_Y}Running Backup Module Tests${C_RST}"
    echo "=============================="
    
    # Run all tests
    test_backup_help
    test_backup_create_valid
    test_backup_create_invalid
    test_backup_list
    test_backup_restore_valid
    test_backup_restore_missing
    test_backup_restore_corrupted
    
    # Print summary
    echo ""
    echo "=============================="
    echo "Test Summary:"
    echo -e "  ${C_G}Passed: $TESTS_PASSED${C_RST}"
    echo -e "  ${C_R}Failed: $TESTS_FAILED${C_RST}"
    echo "=============================="
    
    # Exit with appropriate code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${C_G}All tests passed!${C_RST}"
        exit 0
    else
        echo -e "${C_R}Some tests failed!${C_RST}"
        exit 1
    fi
}

# Run tests
main
