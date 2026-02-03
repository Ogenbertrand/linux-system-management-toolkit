# Logging System

## Overview

The Linux System Management Toolkit (LSMT) includes a robust, configurable logging system (introduced in LSMT-015). This system provides detailed execution logs, error tracking, and automatic log rotation to help administrators monitor toolkit activity and troubleshoot issues.

## Configuration

Logging is configured via the main configuration file: `config/toolkit.conf`.

### Available Options

| Option | Description | Default |
| :--- | :--- | :--- |
| `LOG_DIR` | Directory where log files are stored. | `./logs` |
| `LOG_FILE` | Full path to the active log file. | `${LOG_DIR}/toolkit.log` |
| `LOG_LEVEL` | Minimum severity level to log. Options: `DEBUG`, `INFO`, `WARN`, `ERROR`. | `INFO` |
| `LOG_RETENTION_DAYS` | Number of days to keep old logs before deletion. | `7` |
| `LOG_ENABLED_MODULES` | Comma-separated list of modules to log (e.g., `disk,system`) or `all`. | `all` |

### Example Configuration

```bash
# Logging
LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/toolkit.log"
LOG_LEVEL="DEBUG"
LOG_RETENTION_DAYS=30
LOG_ENABLED_MODULES="disk,backup"
```

## Log Format

Logs are written in the following format:

```text
[YYYY-MM-DD HH:MM:SS] [LEVEL] [MODULE] Message
```

**Example:**
```text
[2026-02-03 15:30:01] [INFO] [system] Executing: memory
[2026-02-03 15:30:02] [INFO] [system] Finished: memory (Success)
[2026-02-03 15:35:10] [ERROR] [disk] Command 'format' not found in module 'disk'
```

## Log Rotation

The toolkit automatically manages log files to prevent them from consuming too much disk space.

1.  **Rotation**: On every execution, the toolkit checks if the current log file is from a previous day. If so, it renames the file to `toolkit.log.YYYY-MM-DD` and compresses it (if `gzip` is available).
2.  **Cleanup**: Logs older than `LOG_RETENTION_DAYS` are automatically deleted.

## Developer Guide

When developing new modules, the logging system is automatically integrated into the main dispatcher.

*   **Automatic Logging**: The dispatcher automatically logs the start and end of every command execution.
*   **Custom Logging**: You can use the `_lsm_log` function within your modules (though currently, this function is internal to the main script; future updates may expose it more directly to modules).

### Log Levels

*   **ERROR**: Critical failures that prevent a command from completing.
*   **WARN**: Non-critical issues or potential problems.
*   **INFO**: Standard operational events (start/stop, status updates).
*   **DEBUG**: Detailed information for development and troubleshooting.
