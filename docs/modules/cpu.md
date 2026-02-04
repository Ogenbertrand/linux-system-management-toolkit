# CPU Module Documentation

## Overview

The CPU module provides real-time CPU usage monitoring and statistics, including total system usage and per-core breakdown.

## Commands

### usage

Display real-time CPU usage percentage.

**Usage:**
```bash
lsm cpu usage [options] [interval]
```

**Options:**
- `-a, --all`: Show per-core CPU statistics in addition to the total.
- `[interval]`: Optional integer value. If provided, the command will refresh the statistics every N seconds.

**Output:**
- Total CPU usage percentage.
- (Optional) Per-core CPU usage percentage.
- Color-coded results based on usage intensity.

**Color Coding:**
- 🟢 Green: Usage < 75%
- 🟡 Yellow: Usage 75-89%
- 🔴 Red: Usage ≥ 90%

**Example Output:**
```
CPU Usage Report (14:30:05)
===================
Total CPU: 12%

Per-Core Usage:
  cpu0:   15%
  cpu1:   10%
  cpu2:   8%
  cpu3:   14%
```

**Technical Details:**
The module reads from `/proc/stat` to calculate CPU usage. It takes two snapshots with a 1-second interval to determine the active vs. idle time.

**Calculation Formula:**
```
Idle = idle + iowait
Total = user + nice + system + idle + iowait + irq + softirq + steal
DiffTotal = TotalCurrent - TotalPrevious
DiffIdle = IdleCurrent - IdlePrevious
Usage% = (DiffTotal - DiffIdle) * 100 / DiffTotal
```

**Error Handling:**
- Validates readability of `/proc/stat`.
- Gracefully handles cases where `/proc/stat` is missing (though rare on Linux).
- Prevents division by zero errors.

### help

Display help information for the CPU module.

**Usage:**
```bash
lsm cpu help
```

## Requirements

- Linux-based operating system.
- Access to `/proc/stat`.
- `bash` version 4.0+ (for `mapfile` support).

## Examples

### Basic Usage

Check current total CPU usage:
```bash
lsm cpu usage
```

### Detailed Monitoring

Check per-core usage:
```bash
lsm cpu usage --all
```

### Continuous Monitoring

Refresh every 2 seconds:
```bash
lsm cpu usage 2
```
