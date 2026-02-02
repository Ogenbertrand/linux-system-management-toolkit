# Contributing to Linux System Management Toolkit

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)

## Code of Conduct

This project adheres to a Code of Conduct that all contributors are expected to follow. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

## Getting Started

1. **Fork the repository**
2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/linux-system-management-toolkit.git
   cd linux-system-management-toolkit
   ```
3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### Project Structure

```
linux-system-management-toolkit/
├── bin/              # Executable scripts
├── modules/          # Feature modules
├── config/           # Configuration files
├── logs/             # Log files (gitignored)
├── tests/            # Test scripts
├── docs/             # Documentation
├── examples/         # Usage examples
└── .github/          # GitHub workflows and templates
```

### Adding a New Module

1. Create a new file in `modules/` (e.g., `modules/network.sh`)
2. Follow the module template structure (see `docs/MODULE_TEMPLATE.md`)
3. Add documentation in `docs/modules/`
4. Create tests in `tests/`
5. Update README.md with new module information

## Coding Standards

### Shell Script Guidelines

- **Use bash**: All scripts should use `#!/usr/bin/env bash`
- **Enable strict mode**: Use `set -euo pipefail`
- **Shellcheck**: All scripts must pass shellcheck validation
- **Functions**: Use descriptive function names with module prefix
- **Comments**: Add comments for complex logic
- **Error handling**: Always handle errors gracefully

### Naming Conventions

- **Files**: lowercase with hyphens (e.g., `backup-manager.sh`)
- **Functions**: lowercase with underscores (e.g., `system_check_cpu`)
- **Variables**: UPPERCASE for constants, lowercase for local variables
- **Module functions**: Prefix with module name (e.g., `disk_list_partitions`)

### Code Style

```bash
# Good example
function module_command() {
    local param="$1"
    
    if [[ -z "$param" ]]; then
        echo "Error: Parameter required" >&2
        return 1
    fi
    
    # Process logic here
    echo "Success"
}

# Bad example
function cmd {
    echo $1
}
```

## Testing

### Running Tests

```bash
# Run all tests
make test

# Run specific module tests
./tests/test_system.sh

# Run shellcheck
make lint
```

### Writing Tests

- Place tests in `tests/` directory
- Name test files as `test_<module>.sh`
- Use the testing framework in `tests/lib/test_framework.sh`
- Include both positive and negative test cases

Example:
```bash
#!/usr/bin/env bash
source "$(dirname "$0")/lib/test_framework.sh"

test_module_function() {
    # Test logic here
    assert_equals "expected" "$(module_function)"
}

run_tests
```

## Submitting Changes

### Pull Request Process

1. **Update documentation**: Ensure all changes are documented
2. **Run tests**: All tests must pass
3. **Update CHANGELOG**: Add entry for your changes
4. **Commit messages**: Use clear, descriptive commit messages
5. **Create PR**: Submit pull request with detailed description

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Build/tooling changes

Example:
```
feat(backup): add incremental backup support

Implemented incremental backup functionality using rsync.
This reduces backup time and storage requirements.

Closes #123
```

### Code Review

- Be respectful and constructive
- Address all review comments
- Keep PRs focused and reasonably sized
- Respond to feedback promptly

## Questions?

If you have questions, please:
- Check existing documentation in `docs/`
- Search existing issues
- Create a new issue with the `question` label

Thank you for contributing!
