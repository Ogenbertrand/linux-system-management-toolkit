# Disk Module Documentation

The Disk module provides utilities for managing and listing disks and partitions on a Linux system.

## Commands

### list

Lists all attached disks and partitions.

**Usage:**
```bash
lsm disk list
```

**Output Columns:**
- `NAME`: Device name
- `SIZE`: Size of the device
- `TYPE`: Device type (disk, part, loop, etc.)
- `MOUNTPOINT`: Mount point (if mounted)

**Dependencies:**
- `lsblk` (util-linux)

## Examples

Listing all disks:
```bash
./bin/lsm-toolkit disk list
```

Showing help:
```bash
./bin/lsm-toolkit disk help
```
