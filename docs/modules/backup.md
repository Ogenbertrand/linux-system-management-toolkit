# Backup Module

## Overview

The **Backup Module** provides comprehensive backup and restore functionality for the Linux System Management Toolkit. It allows you to create timestamped, compressed backups of directories and files, and restore them when needed.

## Features

- **Create Backups**: Generate timestamped compressed archives of directories or files
- **Restore Backups**: Restore backups to original or custom locations with integrity validation
- **List Backups**: View all available backups with size and date information
- **Configurable Compression**: Support for gzip, bzip2, xz, or no compression
- **Error Handling**: Comprehensive validation for missing or corrupted backup files

## Commands

### backup create

Create a backup of a directory or file.

**Usage:**
```bash
lsm backup create <path>
```

**Example:**
```bash
lsm backup create /home/user/documents
```

This will create a backup file like `backups/documents_20260203_152545.tar.gz`.

**Features:**
- Automatically creates backup directory if it doesn't exist
- Generates timestamped filenames for uniqueness
- Uses configured compression method
- Validates source path exists before backup

---

### backup restore

Restore a backup to its original location or a specified directory.

**Usage:**
```bash
lsm backup restore <backup_file> [target_directory]
```

**Examples:**
```bash
# Restore to current location
lsm backup restore backups/documents_20260203_152545.tar.gz

# Restore to a specific directory
lsm backup restore backups/documents_20260203_152545.tar.gz /tmp/restore
```

**Features:**
- Validates backup file exists and is readable
- Checks archive integrity before restoration
- Handles corrupted backups gracefully
- Creates target directory if it doesn't exist

---

### backup list

List all available backups in the backup directory.

**Usage:**
```bash
lsm backup list
```

**Output:**
- Backup filename
- File size
- Creation date

---

### backup help

Display help information for the backup module.

**Usage:**
```bash
lsm backup help
lsm backup --help
```

## Configuration

The backup module reads configuration from `config/toolkit.conf`. Available settings:

```bash
# Backup settings
BACKUP_DIR="./backups"              # Directory where backups are stored
BACKUP_COMPRESSION="gzip"           # Compression method
BACKUP_RETENTION_DAYS=30           # Retention policy (future feature)
```

### Compression Options

- **gzip** (default): Fast compression, `.tar.gz` extension
- **bzip2**: Better compression ratio, `.tar.bz2` extension
- **xz**: Best compression ratio, `.tar.xz` extension
- **none**: No compression, `.tar` extension

## Error Handling

The backup module handles various error conditions gracefully:

### backup create errors:
- Missing source path argument
- Source path does not exist
- Insufficient permissions
- Disk space issues during backup creation

### backup restore errors:
- Missing backup file argument
- Backup file does not exist
- Backup file is not readable
- Corrupted or invalid tar archive
- Insufficient permissions during extraction

All errors display informative messages and return appropriate exit codes.

## Examples

### Basic Workflow

1. **Create a backup:**
   ```bash
   lsm backup create /home/user/important-data
   ```
   Output:
   ```
   Creating backup of: /home/user/important-data
   Backup file: ./backups/important-data_20260203_152545.tar.gz
   Compression: gzip

   ✓ Backup created successfully!
     File: ./backups/important-data_20260203_152545.tar.gz
     Size: 42M
   ```

2. **List available backups:**
   ```bash
   lsm backup list
   ```
   Output:
   ```
   Available Backups
   =================

   important-data_20260203_152545.tar.gz
     Size: 42M
     Date: 2026-02-03 15:25:45

   Total backups: 1
   ```

3. **Restore a backup:**
   ```bash
   lsm backup restore backups/important-data_20260203_152545.tar.gz /tmp
   ```
   Output:
   ```
   Validating backup archive...
   Extracting to: /tmp
   Restoring from: backups/important-data_20260203_152545.tar.gz

   important-data/
   important-data/file1.txt
   important-data/file2.txt

   ✓ Backup restored successfully!
     Location: /tmp
   ```

### Advanced Usage

**Use different compression:**
```bash
# Edit config/toolkit.conf
BACKUP_COMPRESSION="xz"

# Create backup with xz compression
lsm backup create /home/user/documents
```

**Restore to original location:**
```bash
# If original was at /home/user/documents, cd to /home/user first
cd /home/user
lsm backup restore ../../backups/documents_20260203_152545.tar.gz
```

## Testing

The backup module includes comprehensive automated tests in `tests/test_backup.sh`.

**Run tests:**
```bash
bash tests/test_backup.sh
```

**Test coverage:**
- Backup creation with valid sources
- Backup creation error handling (non-existent paths)
- Backup restoration with valid archives
- Restoration error handling (missing files, corrupted archives)
- Backup listing functionality
- Module help output

## Implementation Details

The backup module uses `tar` for creating and extracting archives:

**Create operation:**
```bash
tar -czf backup.tar.gz -C /parent/dir dirname
```

**Restore operation:**
```bash
# Validate first
tar -tf backup.tar.gz > /dev/null

# Then extract
tar -xvf backup.tar.gz -C target/dir
```

The module dynamically adjusts compression flags based on configuration:
- `-z` for gzip
- `-j` for bzip2
- `-J` for xz
- No flag for uncompressed

## Future Enhancements

Potential improvements planned:
- Automated backup retention/cleanup based on `BACKUP_RETENTION_DAYS`
- Incremental backups using `rsync`
- Backup encryption support
- Email notifications on backup completion
- Scheduled backups via `cron` integration
- Backup verification checksums

## Troubleshooting

**Backup creation fails:**
- Check source path exists and is readable
- Verify sufficient disk space in backup directory
- Ensure write permissions for backup directory

**Restore fails with "corrupted archive":**
- Verify backup file wasn't modified or truncated
- Check if backup creation completed successfully
- Disk might have been full during backup creation

**"Permission denied" errors:**
- Ensure you have read permissions for source (create)
- Ensure you have write permissions for target (restore)
- Some system directories may require `sudo`

## Related Modules

- **System Module**: Monitor disk space before creating large backups
- **Disk Module**: Check available storage for backups

## See Also

- [CONTRIBUTING.md](../../CONTRIBUTING.md) - How to add new features
- [MODULE_TEMPLATE.md](MODULE_TEMPLATE.md) - Module development guide
- [config/toolkit.conf](../../config/toolkit.conf) - Configuration file
