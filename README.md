# Linux System Management Toolkit

## Overview

**Linux System Management Toolkit** is a lightweight, modular Command-Line Interface (CLI) project designed to simplify and centralize common Linux system administration tasks. Instead of juggling multiple standalone GNU/Linux utilities, this toolkit provides a unified interface for monitoring system health, managing disks, auditing users, and automating backups.

The project is intentionally minimal, script-based, and extensible, making it ideal for Linux administrators, DevOps engineers, students, and power users who want a practical and transparent way to manage Linux systems.

---

## Project Goals

* Provide a **single entry point** for essential system administration tasks
* Reduce repetitive command usage by wrapping common utilities into clear commands
* Remain **lightweight**, with no heavy dependencies
* Be **modular and extensible**, allowing easy addition of new features
* Serve as a **learning-friendly** toolkit for Linux system management

---

## Key Features

### 1. System Monitoring

Quickly inspect the health and performance of the system.

* CPU usage
* Memory usage
* Disk usage
* System uptime and last reboot history
* Running processes

**Underlying tools:** `top`, `htop`, `free`, `df`, `uptime`, `ps`

---

### 2. Disk Management

Manage and inspect storage devices safely.

* List disks and partitions
* Report disk usage (total, used, available, use%) for mounted partitions
* Monitor available storage space
* Identify potential disk issues

**Underlying tools:** `lsblk`, `df`, `mount`, `blkid`

---

### 3. User Auditing

Audit and manage system users efficiently.

* List system users
* View logged-in users
* Check user groups
* Inspect user activity

**Underlying tools:** `who`, `w`, `id`, `groups`, `/etc/passwd`

---

### 4. Backup Automation

Automate simple and reliable backups with restore capabilities.

* Create timestamped directory backups
* Restore backups to original or custom locations
* List all available backups
* Configurable compression (gzip, bzip2, xz, or none)
* Validate backup integrity before restoration

**Examples:**

```bash
# Create a backup of a directory
lsm backup create /home/user/documents

# List all available backups
lsm backup list

# Restore a backup to its original location
lsm backup restore backups/documents_20260203_120000.tar.gz

# Restore to a custom directory
lsm backup restore backups/documents_20260203_120000.tar.gz /tmp/restore

# Get help for backup commands
lsm backup help
```

**Configuration:**

Edit `config/toolkit.conf` to customize backup behavior:

```bash
BACKUP_DIR="./backups"              # Where backups are stored
BACKUP_COMPRESSION="gzip"           # Compression: gzip, bzip2, xz, or none
BACKUP_RETENTION_DAYS=30           # Retention policy (future feature)
```

**Underlying tools:** `tar`, `rsync`, `cron`

---

## Architecture

The toolkit follows a **modular shell-based architecture**:

```
linux-system-management-toolkit/
├── bin/
│   └── lsm-toolkit        # Main CLI entry point
├── modules/
│   ├── system.sh          # System monitoring functions
│   ├── disk.sh            # Disk management functions
│   ├── users.sh           # User auditing functions
|   ├── uptime.sh
│   └── backup.sh          # Backup automation functions
├── tests/
|   └──test_uptime.sh
├── config/
│   └── toolkit.conf       # Configuration file
├── logs/
│   └── toolkit.log        # Execution logs
└── README.md
```

Each module is independent and can be maintained or extended without affecting others. More detailed information about each module can be found in the `docs/modules/` directory.

- [Users Module](docs/modules/users.md)

---

## Installation

### Requirements

* Linux-based OS
* Bash shell
* Standard GNU/Linux utilities (preinstalled on most distros)

### Steps

```bash
git clone https://github.com/Ogenbertrand/linux-system-management-toolkit
cd linux-system-management-toolkit
chmod +x bin/lsm-toolkit
sudo ln -s $(pwd)/bin/lsm-toolkit /usr/local/bin/lsm
```

---

## Usage

### General Syntax

```bash
lsm <module> <command>
```

### Examples

```bash
lsm system status
lsm disk list

lsm users list
lsm users list [username]
lsm disk usage
lsm users logged-in
lsm backup create /home/user
lsm uptime list
```

---

## Development and Testing

### Running Tests

We use a `Makefile` to manage development tasks. To run all tests:

```bash
make test
```

### Linting

To check for shell script issues (requires `shellcheck`):

```bash
make lint
```

### Adding New Modules

Refer to [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/MODULE_TEMPLATE.md](docs/MODULE_TEMPLATE.md) for guidelines on adding new features.

---

## Configuration

Configuration options are stored in:

```
config/toolkit.conf
```

You can define:

* Default backup directory
* Log file location
* Compression options

---

## Logging

All actions are logged for auditing and troubleshooting:

```
logs/toolkit.log
```

---

## Security Considerations

* Some commands require **root privileges**
* Backup and disk operations should be used carefully
* No sensitive data is transmitted externally

---

## Use Cases

* Linux system administration
* Server monitoring
* DevOps and automation tasks
* Academic learning projects
* Personal Linux management scripts

---

## Future Improvements

* Interactive TUI mode
* Email or webhook alerts
* Plugin system for custom modules
* Container-aware monitoring

---

## License

This project is licensed under the **MIT License**.

---

## Author

Developed as a practical Linux system management toolkit focused on simplicity, clarity, and real-world usability.
