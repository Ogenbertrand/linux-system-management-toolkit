# Backup Module Usage Guide

## Overview

The `backup` module creates timestamped backup archives of directories with optional compression.

## Commands

### `backup create`

Creates a timestamped backup archive of a source directory in the destination directory.

#### Syntax
```bash
lsm backup create <source_dir> <dest_dir> [compression]
```

#### Parameters
- `source_dir`: Directory to back up (must exist)
- `dest_dir`: Destination directory for the backup archive (created if it doesn't exist)
- `compression`: Optional compression type
  - `gzip`: Creates a `.tar.gz` archive
  - `none`: Creates a `.tar` archive (default)

#### Examples

**Basic backup (no compression)**
```bash
lsm backup create /home/user/documents /var/backups
```
Expected output:
```
Backup created: /var/backups/documents_20260203_143022.tar
```

**Compressed backup**
```bash
lsm backup create /home/user/documents /var/backups gzip
```
Expected output:
```
Backup created: /var/backups/documents_20260203_143022.tar.gz
```

#### Archive Naming
Archives are named using the format:
```
<basename>_<YYYYMMDD>_<HHMMSS>.<extension>
```
- `<basename>`: Base name of the source directory
- `<YYYYMMDD>_<HHMMSS>`: Timestamp when backup was created
- `<extension>`: `.tar` or `.tar.gz` depending on compression

### `backup help`

Shows help information for the backup module.

```bash
lsm backup help
```

## Error Handling

The module will return errors for:
- Missing source or destination directories
- Non-existent source directory
- `tar` command not available
- Unsupported compression option
- Failed archive creation

Example error output:
```bash
Error: source and destination directories are required.
```

## Validation

After creation, the module verifies:
- The archive file exists
- The archive file is not empty

If validation fails, it reports:
```bash
Error: backup creation failed.
```

## Dependencies

- `tar` (required)
- Standard GNU/Linux utilities (`date`, `dirname`, `basename`)

## Testing

To verify the backup module works correctly:

```bash
# Create test directories and files
mkdir -p /tmp/lsm-test-src /tmp/lsm-test-backups
echo "test file" > /tmp/lsm-test-src/test.txt

# Create backup
./bin/lsm-toolkit backup create /tmp/lsm-test-src /tmp/lsm-test-backups gzip

# Verify archive contents
tar -tzf /tmp/lsm-test-backups/lsm-test-src_*.tar.gz
```

Expected verification output:
```
lsm-test-src/
lsm-test-src/test.txt
```
