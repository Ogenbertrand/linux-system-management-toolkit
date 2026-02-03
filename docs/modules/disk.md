# Disk Module Documentation

The Disk module provides utilities for managing and listing disks and partitions, and for reporting disk space usage on a Linux system.

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

### usage

Reports disk space usage for all mounted partitions: total, used, and available space, plus usage percentage. Optionally shows threshold warnings when usage exceeds a configured percentage.

**Usage:**
```bash
lsm disk usage
```

**Example Output:**
```
Disk space usage (mounted partitions)
=====================================
FILESYSTEM                    TOTAL       USED  AVAILABLE   USE% MOUNTED ON
---------                     -----       ----  ---------   ---- ----------
tmpfs                          3.2G        48M       3.1G     2% /run
/dev/nvme0n1p3                 932G       380G       506G    43% /
tmpfs                           16G       891M        15G     6% /dev/shm
/dev/nvme0n1p1                 599M       8.3M       591M     2% /boot/efi
```

**Output Columns:**
- `FILESYSTEM`: Device or filesystem name
- `TOTAL`: Total size (human-readable)
- `USED`: Used space
- `AVAILABLE`: Available space
- `USE%`: Usage percentage
- `MOUNTED ON`: Mount point

**Optional threshold warnings**

When `ALERT_DISK_THRESHOLD` is set in `config/toolkit.conf` (e.g. `ALERT_DISK_THRESHOLD=90`), any partition at or above that percentage is reported in a warning section at the end of the output:

```
Threshold warnings (ALERT_DISK_THRESHOLD=90%):

  WARNING: / is at 92% (threshold: 90%)
```

Set `ALERT_DISK_THRESHOLD=0` or omit it to disable warnings.

**Dependencies:**
- `df` (coreutils) — uses `df -h -P` for space statistics

## Examples

Listing all disks:
```bash
./bin/lsm-toolkit disk list
```

Reporting disk space usage for mounted partitions:
```bash
./bin/lsm-toolkit disk usage
```

Showing help:
```bash
./bin/lsm-toolkit disk help
```
