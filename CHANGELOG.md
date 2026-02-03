# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure
- Documentation templates
- Development guidelines
- Disk Listing Utility module (LSMT-003)
- Disk usage check module (LSMT-004)
- Memory usage reporting feature (LSMT-002)
- System monitoring module with memory command
- Backup automation module with create, restore, and list commands (LSMT-010)
- Comprehensive backup module documentation in docs/modules/backup.md
- Automated test suite for backup module

### Changed
- Updated main CLI to pass command arguments to module functions
- Enhanced README.md with detailed backup usage examples and configuration

### Fixed
- Fixed CLI argument passing bug that prevented modules from receiving parameters

## [1.0.0] - YYYY-MM-DD

### Added
- System monitoring module
- Disk management module
- User auditing module
- Backup automation module
- Configuration system
- Logging system

[Unreleased]: https://github.com/Ogenbertrand/linux-system-management-toolkit/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Ogenbertrand/linux-system-management-toolkit/releases/tag/v1.0.0
