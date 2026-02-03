# System Module Documentation

## Overview

The System module provides comprehensive system monitoring and health check functionality for the Linux System Management Toolkit.

## Commands

### memory

Display current memory and swap usage with detailed statistics.

**Usage:**
```bash
lsm system memory
```

**Output:**
- Total memory
- Used memory
- Free memory
- Available memory
- Memory usage percentage (color-coded)
- Swap information (if configured)
- Swap usage percentage (color-coded)

**Color Coding:**
- 🟢 Green: Usage < 75%
- 🟡 Yellow: Usage 75-89%
- 🔴 Red: Usage ≥ 90%

**Example Output:**
```
Memory Usage Report
===================

Memory:
  Total:     16.0 GB
  Used:      8.5 GB
  Free:      3.2 GB
  Available: 7.5 GB
  Usage:     53%

Swap:
  Total:     8.0 GB
  Used:      1.2 GB
  Free:      6.8 GB
  Usage:     15%
```

**Technical Details:**

The memory command uses two methods to retrieve memory information:

1. **Primary Method**: `free -k` command
   - Faster and more reliable
   - Provides both memory and swap information
   - Includes "available" memory metric

2. **Fallback Method**: `/proc/meminfo` parsing
   - Used when `free` command is not available
   - Direct kernel memory statistics
   - Ensures compatibility across different Linux distributions

**Error Handling:**

The command handles the following scenarios:
- Missing `free` command (falls back to `/proc/meminfo`)
- Unreadable `/proc/meminfo` file
- Systems without swap configured
- Division by zero for percentage calculations
- Invalid or missing memory values

**Exit Codes:**
- `0`: Success
- `1`: Error retrieving memory information

### help

Display help information for the system module.

**Usage:**
```bash
lsm system help
```

## Future Commands

The following commands are planned for future releases:

- `cpu` - Display CPU usage and load averages
- `disk` - Display disk usage across all mounted filesystems
- `uptime` - Display system uptime and load
- `processes` - Display running processes and resource usage
- `status` - Comprehensive system health overview

## Requirements

- Linux-based operating system
- One of the following:
  - `free` command (part of procps package)
  - Access to `/proc/meminfo`
- `awk` for calculations and formatting

## Examples

### Basic Usage

Check memory usage:
```bash
lsm system memory
```

### Integration with Scripts

```bash
#!/bin/bash

# Check if memory usage is critical
output=$(lsm system memory)
if echo "$output" | grep -q "9[0-9]%"; then
    echo "Warning: High memory usage detected!"
fi
```

### Monitoring

```bash
# Monitor memory every 5 seconds
watch -n 5 lsm system memory
```

## Troubleshooting

### "Error: Cannot read /proc/meminfo"

**Cause**: Permission issues or `/proc` filesystem not mounted

**Solution**:
- Ensure `/proc` is mounted: `mount | grep proc`
- Check file permissions: `ls -l /proc/meminfo`

### "Error: Unable to retrieve memory information"

**Cause**: Both `free` command and `/proc/meminfo` are unavailable

**Solution**:
- Install procps package: `sudo apt install procps` (Debian/Ubuntu)
- Verify `/proc` filesystem is available

### No swap information displayed

**Cause**: System has no swap configured

**Solution**: This is normal behavior. The output will show "No swap configured" instead of swap statistics.

## Notes

- Memory values are displayed in human-readable format (KB, MB, GB)
- Percentages are calculated based on total memory/swap
- The "Available" memory metric represents memory available for new applications without swapping
- Color coding helps quickly identify potential memory issues
