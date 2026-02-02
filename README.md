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
* System uptime
* Running processes

**Underlying tools:** `top`, `htop`, `free`, `df`, `uptime`, `ps`

---

### 2. Disk Management

Manage and inspect storage devices safely.

* List disks and partitions
* Check disk usage and mount points
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

Automate simple and reliable backups.

* Create directory backups
* Timestamped backup archives
* Optional compression
* Restore backups when needed

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
│   └── backup.sh          # Backup automation functions
├── config/
│   └── toolkit.conf       # Configuration file
├── logs/
│   └── toolkit.log        # Execution logs
└── README.md
```

Each module is independent and can be maintained or extended without affecting others.

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
lsm users logged-in
lsm backup create /home/user
```

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
