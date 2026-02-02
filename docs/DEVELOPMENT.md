# Development Guide

## Prerequisites

- Linux-based operating system
- Bash 4.0 or higher
- Git
- Shellcheck (for linting)

## Setup Development Environment

1. **Clone the repository**
   ```bash
   git clone https://github.com/Ogenbertrand/linux-system-management-toolkit.git
   cd linux-system-management-toolkit
   ```

2. **Install shellcheck** (for code quality)
   ```bash
   # Ubuntu/Debian
   sudo apt install shellcheck
   
   # Fedora
   sudo dnf install shellcheck
   
   # macOS
   brew install shellcheck
   ```

3. **Make scripts executable**
   ```bash
   chmod +x bin/lsm-toolkit
   ```

## Project Structure

```
linux-system-management-toolkit/
├── bin/                    # Executable entry points
│   └── lsm-toolkit        # Main CLI script
├── modules/               # Feature modules
│   ├── system.sh         # System monitoring
│   ├── disk.sh           # Disk management
│   ├── users.sh          # User auditing
│   └── backup.sh         # Backup automation
├── config/               # Configuration files
│   └── toolkit.conf      # Main configuration
├── logs/                 # Log files (gitignored)
├── tests/                # Test scripts
│   ├── lib/             # Test framework
│   └── test_*.sh        # Module tests
├── docs/                 # Documentation
│   ├── MODULE_TEMPLATE.md
│   └── modules/         # Module-specific docs
├── examples/            # Usage examples
└── .github/             # GitHub workflows
    └── workflows/
```

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Develop Your Feature

Follow the module template in `docs/MODULE_TEMPLATE.md`

### 3. Test Your Code

```bash
# Run shellcheck
make lint

# Run tests
make test

# Test manually
./bin/lsm-toolkit your_module command
```

### 4. Commit Your Changes

```bash
git add .
git commit -m "feat(module): description of changes"
```

### 5. Push and Create PR

```bash
git push origin feature/your-feature-name
```

## Coding Standards

### Shell Script Best Practices

1. **Use strict mode**
   ```bash
   set -euo pipefail
   ```

2. **Quote variables**
   ```bash
   # Good
   echo "$variable"
   
   # Bad
   echo $variable
   ```

3. **Use functions**
   ```bash
   function_name() {
       local param="$1"
       # function body
   }
   ```

4. **Handle errors**
   ```bash
   if ! command; then
       echo "Error message" >&2
       return 1
   fi
   ```

5. **Use meaningful names**
   ```bash
   # Good
   user_count=$(wc -l < /etc/passwd)
   
   # Bad
   x=$(wc -l < /etc/passwd)
   ```

## Testing

### Writing Tests

Create test files in `tests/` directory:

```bash
#!/usr/bin/env bash

# Source the module
source "$(dirname "$0")/../modules/your_module.sh"

# Test function
test_your_function() {
    local result
    result=$(your_module_function)
    
    if [[ "$result" == "expected" ]]; then
        echo "✓ Test passed"
        return 0
    else
        echo "✗ Test failed"
        return 1
    fi
}

# Run test
test_your_function
```

### Running Tests

```bash
# All tests
make test

# Specific test
./tests/test_your_module.sh
```

## Debugging

### Enable Debug Mode

```bash
# Run with debug output
bash -x ./bin/lsm-toolkit module command

# Or set in script
set -x
```

### Check Logs

```bash
tail -f logs/toolkit.log
```

## Common Tasks

### Adding a New Module

1. Create `modules/new_module.sh`
2. Follow the template in `docs/MODULE_TEMPLATE.md`
3. Create `tests/test_new_module.sh`
4. Add documentation in `docs/modules/new_module.md`
5. Update README.md

### Updating Configuration

Edit `config/toolkit.conf` with new settings

### Adding Dependencies

Document in README.md and check in module code:

```bash
if ! command -v required_tool &> /dev/null; then
    echo "Error: required_tool is not installed" >&2
    exit 1
fi
```

## Release Process

1. Update version in `bin/lsm-toolkit`
2. Update CHANGELOG.md
3. Create git tag
4. Push to repository

## Getting Help

- Read documentation in `docs/`
- Check existing issues on GitHub
- Ask questions in discussions
