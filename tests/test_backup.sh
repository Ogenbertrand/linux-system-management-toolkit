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
    local output
    output=$("$LSM_TOOLKIT" backup help 2>&1)
    local exit_code=$?
    assert "Help command succeeds" '[[ $exit_code -eq 0 ]]'
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
    local output
    output=$("$LSM_TOOLKIT" backup create "$TEST_SOURCE" 2>&1)
    local exit_code=$?
    
    assert "Create command succeeds" '[[ $exit_code -eq 0 ]]'
    assert "Backup file is created" '[[ -n "$(find "$TEST_BACKUP_DIR" -name "source_*.tar.gz" 2>/dev/null)" ]]'
    assert "Output contains success message" '[[ "$output" =~ "successfully" ]]'
    
    teardown
}

# Test: incremental backup creates snapshot
test_backup_create_incremental() {
    echo ""
    echo "Test: Backup create incremental snapshot"
    setup

    cd "$TEST_DIR" || exit 1
    local output
    output=$("$LSM_TOOLKIT" backup create --incremental "$TEST_SOURCE" 2>&1)
    local exit_code=$?

    assert "Incremental create command succeeds" '[[ $exit_code -eq 0 ]]'
    assert "Incremental series directory is created" '[[ -d "${TEST_BACKUP_DIR}/source.lsm" ]]'
    assert "Latest symlink exists" '[[ -e "${TEST_BACKUP_DIR}/source.lsm/snapshots/latest" ]]'

    local latest_snapshot
    latest_snapshot=$(readlink -f "${TEST_BACKUP_DIR}/source.lsm/snapshots/latest")
    assert "Latest snapshot directory exists" '[[ -d "$latest_snapshot" ]]'
    assert "Snapshot contains backed up files" '[[ -f "${latest_snapshot}/source/file1.txt" ]]'
    assert "Output contains success message" '[[ "$output" =~ "successfully" ]]'

    teardown
}

# Test: incremental backup uses hardlinks for unchanged files
test_backup_incremental_hardlinks() {
    echo ""
    echo "Test: Incremental backup hardlinks unchanged files"
    setup

    cd "$TEST_DIR" || exit 1

    "$LSM_TOOLKIT" backup create --incremental "$TEST_SOURCE" > /dev/null 2>&1
    echo "Modified" > "${TEST_SOURCE}/file2.txt"
    "$LSM_TOOLKIT" backup create --incremental "$TEST_SOURCE" > /dev/null 2>&1

    local snapshots_dir="${TEST_BACKUP_DIR}/source.lsm/snapshots"
    local first_snapshot
    local second_snapshot
    first_snapshot=$(find "$snapshots_dir" -maxdepth 1 -mindepth 1 -type d ! -name latest | sort | head -n 1)
    second_snapshot=$(find "$snapshots_dir" -maxdepth 1 -mindepth 1 -type d ! -name latest | sort | tail -n 1)

    local inode_first
    local inode_second
    inode_first=$(stat -c %i "${first_snapshot}/source/file1.txt")
    inode_second=$(stat -c %i "${second_snapshot}/source/file1.txt")

    assert "Unchanged file is hardlinked across snapshots" '[[ "$inode_first" == "$inode_second" ]]'

    local inode_mod_first
    local inode_mod_second
    inode_mod_first=$(stat -c %i "${first_snapshot}/source/file2.txt")
    inode_mod_second=$(stat -c %i "${second_snapshot}/source/file2.txt")
    assert "Modified file is not hardlinked" '[[ "$inode_mod_first" != "$inode_mod_second" ]]'

    teardown
}

# Test: restore from incremental snapshot directory
test_backup_restore_snapshot() {
    echo ""
    echo "Test: Backup restore from snapshot directory"
    setup

    cd "$TEST_DIR" || exit 1

    "$LSM_TOOLKIT" backup create --incremental "$TEST_SOURCE" > /dev/null 2>&1
    local latest_snapshot
    latest_snapshot=$(readlink -f "${TEST_BACKUP_DIR}/source.lsm/snapshots/latest")

    rm -rf "$TEST_SOURCE"

    local output
    output=$("$LSM_TOOLKIT" backup restore "$latest_snapshot" "$TEST_DIR" 2>&1)
    local exit_code=$?

    assert "Restore from snapshot succeeds" '[[ $exit_code -eq 0 ]]'
    assert "Source directory is restored" '[[ -d "$TEST_SOURCE" ]]'
    assert "File1 is restored" '[[ -f "${TEST_SOURCE}/file1.txt" ]]'
    assert "Output contains success message" '[[ "$output" =~ "successfully" ]]'

    teardown
}

# Test: backup create with non-existent source
test_backup_create_invalid() {
    echo ""
    echo "Test: Backup create with non-existent source"
    setup
    
    cd "$TEST_DIR" || exit 1
    local output
    output=$("$LSM_TOOLKIT" backup create "/nonexistent/path" 2>&1)
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
    
    local output
    output=$("$LSM_TOOLKIT" backup list 2>&1)
    local exit_code=$?
    
    assert "List command succeeds" '[[ $exit_code -eq 0 ]]'
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
    local output
    output=$("$LSM_TOOLKIT" backup restore "$backup_file" "$TEST_DIR" 2>&1)
    local exit_code=$?
    
    assert "Restore command succeeds" '[[ $exit_code -eq 0 ]]'
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
    local output
    output=$("$LSM_TOOLKIT" backup restore "/nonexistent/backup.tar.gz" 2>&1)
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
    
    local output
    output=$("$LSM_TOOLKIT" backup restore "$fake_backup" 2>&1)
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
    test_backup_create_incremental
    test_backup_incremental_hardlinks
    test_backup_create_invalid
    test_backup_list
    test_backup_restore_valid
    test_backup_restore_snapshot
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
