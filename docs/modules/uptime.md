# Uptime Module Documentation

## Overview

The Uptime module provides essential information about the system's operational duration and recent reboot history. It is designed to be robust, handling various system configurations and providing clear, human-readable output.

## Commands

### list

Displays the total system uptime in days, hours, and minutes, and includes the timestamp of the last system reboot.

**Usage:**
```bash
lsm uptime list
```

**Output Details:**
- `System Uptime Information`: A header indicating the start of the uptime report.
- `Total Uptime`: The duration since the last system boot, formatted in days, hours, and minutes.
- `Last Reboot`: The date and time of the most recent system reboot.

**Example Output:**
```
--- System Uptime Information ---
Total Uptime: 3 weeks, 5 days, 57 minutes
Last Reboot: Thu Jan 8 10:42
```

### help

Displays comprehensive help information for the uptime module, including usage, commands, and examples.

**Usage:**
```bash
lsm uptime help
```

## Technical Details

The `uptime` module employs a dual-strategy approach to retrieve system uptime:

1.  **Primary Method**: `uptime -p` command
    -   Utilizes the `uptime -p` command for a concise, human-readable uptime string.
    -   This method is preferred for its simplicity and direct output.

2.  **Fallback Method**: `/proc/uptime` parsing
    -   If `uptime -p` is not available or fails (e.g., on older systems or minimal environments), the module falls back to parsing `/proc/uptime`.
    -   `/proc/uptime` provides uptime in seconds, which is then converted into days, hours, and minutes.

For the last reboot timestamp, the module uses the `last reboot` command, parsing its output to extract the relevant date and time information.

## Error Handling

The module is designed to handle the following scenarios gracefully:

-   **`uptime -p` command not found**: Automatically switches to parsing `/proc/uptime`.
-   **`/proc/uptime` unreadable**: If `/proc/uptime` cannot be read, the uptime information will be reported as unavailable.
-   **`last reboot` command not found or no reboot history**: If the `last` command is not available or no reboot entries are found, "Last Reboot: Not available" will be displayed.

## Requirements

-   Linux-based operating system.
-   One of the following for uptime calculation:
    -   `uptime` command (typically part of `procps` or `util-linux` packages).
    -   Access to `/proc/uptime`.
-   `last` command (typically part of `util-linux` package) for last reboot information.
-   `awk` for parsing `last reboot` output.

## Examples

### Basic Uptime Report

To get a quick overview of the system's uptime and last reboot:
```bash
lsm uptime list
```

### Viewing Module Help

To see all available commands and options for the uptime module:
```bash
lsm uptime help
```

## Notes

-   The module prioritizes `uptime -p` for its user-friendly output. The fallback to `/proc/uptime` ensures broad compatibility.
-   The `last reboot` command might show different output formats across various Linux distributions; the parsing logic is designed to be as robust as possible.
