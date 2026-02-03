# Disk Module Documentation

The Disk module provides utilities for managing and listing disks and partitions on a Linux system.

## Commands

### list

Lists all attached disks and partitions.

**Usage:**
```bash
lsm disk list
```


**Example Output:**
```
Listing attached disks and partitions...
------------------------------------------------------------
NAME          SIZE TYPE MOUNTPOINT
loop0           4K loop /snap/bare/5
loop1        63.8M loop /snap/core20/2682
loop2        55.5M loop /snap/core18/2976
loop3        55.5M loop /snap/core18/2979
loop4        63.8M loop /snap/core20/2686
loop5        73.9M loop /snap/core22/2216
loop6          74M loop /snap/core22/2292
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
