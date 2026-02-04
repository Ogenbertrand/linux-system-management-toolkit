# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Configurable log management system (LSMT-015)
  - Support for log levels (DEBUG, INFO, WARN, ERROR)
  - Automatic daily log rotation and compression
  - Configurable log retention policy
  - Module-level log filtering
- Initial project structure
- Documentation templates
- Development guidelines
- Implement Active Users Listing (LSMT-006) in Users module
- Enhanced CLI dispatcher to support command argument
- Disk Listing Utility module (LSMT-003)
- Disk usage check module (LSMT-004)
- Memory usage reporting feature (LSMT-002)
- System monitoring module with memory command
- System Uptime reporting command to the System Module (LSMT-005)
- Automated test suite `test_uptime.sh` for module validation
- New `health` command to the `disk` module for monitoring SMART health status on SATA and NVMe drives.
- Integration tests in `modules/test.sh` for the disk health module.
- Technical documentation for the Disk Monitor module in `docs/DISK_MONITOR.md`.
- Implement System CPU Monitoring (LSMT-001) as a standalone module
- Fixed pre-existing syntax error in `bin/lsm-toolkit` dispatcher
- Fixed duplicate command execution bug in `bin/lsm-toolkit`

## [1.0.0] - YYYY-MM-DD

### Added
- System monitoring module
- Disk management module
- User auditing module
- Backup automation module
- Configuration system
- Backup module with timestamped archive creation and optional gzip compression
- Comprehensive backup usage documentation
- Argument passing fix in main script for module functions

### Changed
- Logging system

### Added

- Real-time process monitoring feature (LSMT-004)

- lsm system processes command for monitoring top processes
- Configurable refresh interval (--refresh N)
- Configurable process count (--count N)
- Sorting by CPU or memory usage (--sort cpu|mem)
- Automatic terminal resize handling
- Color-coded display for better readability
- Graceful exit with Ctrl+C
- Support for both ps and top commands (fallback mechanism)

[Unreleased]: https://github.com/Ogenbertrand/linux-system-management-toolkit/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Ogenbertrand/linux-system-management-toolkit/releases/tag/v1.0.0
