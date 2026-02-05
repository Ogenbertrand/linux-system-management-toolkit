# Backup Module Usage Guide

## Overview

The `backup` module creates timestamped backups of directories/files.

It supports two backup styles:
- **Archive backups** (default): create a `.tar*` archive under `BACKUP_DIR`.
- **Incremental snapshots** (`--incremental`): create a snapshot directory that is a **full restore point** while only storing changed files (uses hardlinks via `rsync --link-dest`).

## Commands

### `backup create`

Creates a backup of a source path.

#### Syntax
```bash
lsm backup create <path>

lsm backup create --incremental [--compress|--no-compress] [--base <snapshot_dir>] <path>
```

#### Parameters
- `path`: Directory or file to back up (must exist)

#### Options
- `--incremental`: Create an incremental snapshot series for the given `path`.
- `--base <snapshot_dir>`: Use a specific snapshot as the `--link-dest` base (optional). By default the module uses the `latest` snapshot if available.
- `--compress`: For incremental snapshots, also create a compressed tar archive artifact of the snapshot.
- `--no-compress`: For incremental snapshots, do not create an archive artifact (**default**).

#### Examples

**Basic backup (no compression)**
```bash
lsm backup create /home/user/documents
```

**Compressed backup**
```bash
lsm backup create /home/user/documents
```

Compression for archive backups is controlled via `BACKUP_COMPRESSION` in `config/toolkit.conf`.

**Incremental snapshot (full restore point)**
```bash
lsm backup create --incremental /home/user/documents
```

**Incremental snapshot + archive artifact**
```bash
lsm backup create --incremental --compress /home/user/documents
```

#### Archive Naming
Archives are named using the format:
```
<basename>_<YYYYMMDD>_<HHMMSS>.<extension>
```
- `<basename>`: Base name of the source directory
- `<YYYYMMDD>_<HHMMSS>`: Timestamp when backup was created
- `<extension>`: `.tar` or `.tar.gz` depending on compression

Note: the implementation uses a higher-resolution timestamp, so you may also see an additional `_<NANOSECONDS>` suffix.

#### Incremental Snapshot Layout
Incremental snapshots are stored as a “series” under `BACKUP_DIR`:
```
BACKUP_DIR/
  <basename>.lsm/
    meta/
      source_path
      mode
    snapshots/
      latest -> /abs/path/to/<timestamp>
      <timestamp>/
        <basename>/...
    archives/   (only if you used --compress)
      <basename>_<timestamp>.tar.gz
```

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
- `rsync` command not available (incremental mode)
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
- `rsync` (required for `--incremental`)
- Standard GNU/Linux utilities (`date`, `dirname`, `basename`)

## Restore

### Restore from an archive
```bash
lsm backup restore backups/documents_20260203_120000.tar.gz
lsm backup restore backups/documents_20260203_120000.tar.gz /tmp/restore
```

### Restore from an incremental snapshot directory
You can restore directly from a snapshot directory (for example the `latest` snapshot target):
```bash
lsm backup restore backups/documents.lsm/snapshots/20260205_174517_132826515 /tmp/restore
```

Note: snapshot restore uses `rsync -a` and does not delete unrelated files in the target directory.

## Testing

To verify the backup module works correctly:

```bash
# Create test directories and files
mkdir -p /tmp/lsm-test-src /tmp/lsm-test-backups
echo "test file" > /tmp/lsm-test-src/test.txt

# Create backup
BACKUP_DIR=/tmp/lsm-test-backups ./bin/lsm-toolkit backup create /tmp/lsm-test-src

# Verify archive contents
tar -tf /tmp/lsm-test-backups/lsm-test-src_*.tar*
```

Expected verification output:
```
lsm-test-src/
lsm-test-src/test.txt
```
