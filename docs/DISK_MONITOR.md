# Module: Disk Health Monitor

## Description
This module provides a automated way to check the SMART (Self-Monitoring, Analysis, and Reporting Technology) health of all physical drives on the system, including SATA and NVMe disks.

## Features
- Auto-detects all physical disks using `lsblk`.
- Differentiates between SATA and NVMe to pull correct health attributes.
- Reports a summary "PASSED/FAILED" status.

## Dependencies
- **smartmontools**: Required for the `smartctl` command.
- **Sudo Privileges**: Hardware-level health checks require root access.

## Usage
This module is loaded via the LSM Toolkit or can be run manually:
```bash
sudo bash modules/disk.sh