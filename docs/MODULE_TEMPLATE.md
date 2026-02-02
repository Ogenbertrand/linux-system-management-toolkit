# Module Template

Use this template when creating a new module for the Linux System Management Toolkit.

## File Structure

```bash
modules/
└── your_module.sh
```

## Template Code

```bash
#!/usr/bin/env bash

################################################################################
# [Module Name] Module
# 
# Description: [Brief description of what this module does]
# Commands: [list, of, commands]
################################################################################

# Module help
your_module_help() {
    cat << EOF
[Module Name] Module

Usage: lsm your_module <command> [options]

Commands:
  command1    - Description of command1
  command2    - Description of command2

Options:
  -h, --help  Show this help message

Examples:
  lsm your_module command1
  lsm your_module command2

EOF
}

# Command 1
your_module_command1() {
    # Implementation here
    echo "Command 1 executed"
}

# Command 2
your_module_command2() {
    # Implementation here
    echo "Command 2 executed"
}

# Main module function
your_module_main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        command1)
            your_module_command1 "$@"
            ;;
        command2)
            your_module_command2 "$@"
            ;;
        -h|--help)
            your_module_help
            ;;
        *)
            echo "Unknown command: $command"
            your_module_help
            exit 1
            ;;
    esac
}
```

## Guidelines

1. **Naming Convention**: Use `modulename_functionname` format
2. **Help Function**: Always provide a help function
3. **Error Handling**: Handle errors gracefully
4. **Logging**: Use the logging function from main script
5. **Documentation**: Add comments for complex logic

## Testing

Create a corresponding test file in `tests/test_your_module.sh`
