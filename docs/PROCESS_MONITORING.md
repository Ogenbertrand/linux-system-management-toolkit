# System Module Documentation - Process Monitoring

## Overview

The Process Monitoring feature provides real-time visualization of system processes, displaying CPU usage, memory consumption, and process details. This feature is designed to help system administrators quickly identify resource-intensive processes and monitor system performance.

## Commands

### processes

Monitor top processes in real-time with automatic refresh and terminal resize handling.

**Usage:**
```bash
lsm system processes [options]
```

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--refresh N` | Refresh interval in seconds | 3 |
| `--count N` | Number of processes to display | 10 |
| `--sort cpu` | Sort by CPU usage | cpu |
| `--sort mem` | Sort by memory usage | cpu |

**Examples:**

```bash
# Monitor with default settings (3 second refresh, 10 processes, CPU sort)
lsm system processes

# Refresh every 2 seconds
lsm system processes --refresh 2

# Show top 15 processes
lsm system processes --count 15

# Sort by memory usage instead of CPU
lsm system processes --sort mem

# Combine options
lsm system processes --refresh 5 --count 20 --sort mem
```

## Output Format

The process monitor displays the following information:

```
Top Processes Monitor
=====================================
Last updated: 2026-02-03 14:30:45
Press Ctrl+C to exit

PID     CPU%   MEM%   USER     COMMAND
--------------------------------------
1234    45.2   12.3   root     /usr/bin/process-name
5678    23.1   8.5    user     python script.py
...
```

### Column Descriptions

- **PID**: Process ID
- **CPU%**: CPU usage percentage
- **MEM%**: Memory usage percentage  
- **USER**: User running the process
- **COMMAND**: Command/executable name (truncated to fit terminal width)

## Features

### Real-time Monitoring

The monitor refreshes automatically at the specified interval, providing up-to-date process information without manual intervention.

### Terminal Resize Handling

The display automatically adapts to terminal size changes:
- Command column truncates to fit available width
- Layout adjusts dynamically when terminal is resized
- No manual restart required

### Color-Coded Display

- **Headers**: Cyan and bold for easy identification
- **Data**: Clear, readable formatting
- **Footer**: Important information highlighted

### Graceful Exit

Press `Ctrl+C` to exit the monitor cleanly:
- Restores terminal state
- Displays exit message
- No leftover processes or zombie sessions

## Implementation Details

### Command Detection

The module uses a fallback strategy for maximum compatibility:

1. **Primary method**: Uses `ps aux` with sorting
   - More reliable and consistent
   - Better cross-platform support
   - Provides detailed process information

2. **Fallback method**: Uses `top` in batch mode
   - Used when `ps` is unavailable
   - Supports different `top` versions
   - Handles procps-ng and other implementations

### Terminal Handling

The monitor implements proper terminal management:

```bash
# SIGWINCH signal handling for terminal resize
trap _handle_resize WINCH

# ANSI escape codes for screen clearing
printf '\033[2J\033[H'

# Dynamic terminal size detection
tput lines / tput cols
```

### Process Sorting

Processes are sorted by the specified metric:

- **CPU sorting**: Orders by CPU percentage (descending)
- **Memory sorting**: Orders by memory percentage (descending)

### Error Handling

The module validates all inputs and provides clear error messages:

```bash
# Invalid refresh interval
lsm system processes --refresh 0
# Error: Refresh interval must be a positive integer

# Invalid sort option
lsm system processes --sort invalid
# Error: Sort option must be 'cpu' or 'mem'

# Unknown option
lsm system processes --unknown
# Unknown option: --unknown
```

## Requirements

### Minimum Requirements

- Linux-based operating system
- Bash 4.0 or higher
- One of the following:
  - `ps` command (part of procps package)
  - `top` command

### Optional Requirements

- `tput` command (for better terminal handling)
- Color-capable terminal

## Use Cases

### 1. Performance Troubleshooting

Quickly identify processes consuming excessive CPU or memory:

```bash
# Find CPU-intensive processes
lsm system processes --sort cpu

# Find memory hogs
lsm system processes --sort mem --count 20
```

### 2. System Monitoring

Keep an eye on system resource usage during operations:

```bash
# Monitor during deployment
lsm system processes --refresh 2

# Long-term monitoring
lsm system processes --refresh 10 --count 15
```

### 3. Capacity Planning

Understand typical process resource usage patterns:

```bash
# Sample processes over time
lsm system processes --refresh 60 --count 25
```

### 4. Security Auditing

Monitor for unexpected or suspicious processes:

```bash
# Frequent checks for unusual activity
lsm system processes --refresh 1 --count 30
```

## Troubleshooting

### "Neither ps nor top commands are available"

**Cause**: Missing process monitoring utilities

**Solution**:
```bash
# Debian/Ubuntu
sudo apt install procps

# RHEL/CentOS/Fedora
sudo dnf install procps-ng

# Alpine Linux
apk add procps
```

### Display doesn't fit terminal

**Cause**: Terminal too small or process commands too long

**Solution**:
- Resize terminal window
- Commands are automatically truncated with "..."
- Use a larger terminal for better visibility

### Refresh rate too fast/slow

**Cause**: Default refresh interval doesn't match needs

**Solution**:
```bash
# Faster refresh (1 second)
lsm system processes --refresh 1

# Slower refresh (10 seconds)
lsm system processes --refresh 10
```

### Can't exit the monitor

**Cause**: Terminal not responding to Ctrl+C

**Solution**:
- Press `Ctrl+C` firmly
- If stuck, use `Ctrl+Z` to suspend, then `kill %1`
- In worst case, close terminal window

## Performance Considerations

### Refresh Interval

- **Fast refresh (1-2s)**: Higher CPU overhead, real-time monitoring
- **Medium refresh (3-5s)**: Balanced performance and responsiveness
- **Slow refresh (10+s)**: Low overhead, periodic checks

### Process Count

- **Few processes (5-10)**: Minimal overhead
- **Many processes (20-30)**: Slightly higher overhead
- Recommended: 10-20 processes for balance

### Resource Usage

The monitor itself uses minimal resources:
- CPU: < 1% on modern systems
- Memory: < 10 MB
- No persistent storage required

## Comparison with Other Tools

### vs htop

**Advantages**:
- Simpler, focused interface
- No additional installation required
- Part of integrated toolkit

**Disadvantages**:
- Less interactive features
- No process tree view
- Fewer sorting options

### vs top

**Advantages**:
- Clearer, more readable output
- Customizable refresh and count
- Better terminal resize handling

**Disadvantages**:
- Requires separate command
- Not interactive (no kill/renice)

### vs ps

**Advantages**:
- Real-time updates
- Automatic sorting
- User-friendly display

**Disadvantages**:
- No one-time snapshot mode
- Less scriptable

## Future Enhancements

Planned features for future releases:

- [ ] Process filtering by user
- [ ] Interactive process management (kill, renice)
- [ ] Process tree visualization
- [ ] Historical CPU/memory graphs
- [ ] Alert thresholds for high usage
- [ ] Export to file/log
- [ ] Regex filtering by command name

## Contributing

To contribute improvements to the process monitoring feature:

1. Review the code in `modules/system.sh`
2. Follow the coding standards in `CONTRIBUTING.md`
3. Add tests to `tests/test_system_processes.sh`
4. Update this documentation
5. Submit a pull request

## Related Commands

- `lsm system memory` - View memory usage
- `lsm system help` - Show all system module commands

## References

- [ps man page](https://man7.org/linux/man-pages/man1/ps.1.html)
- [top man page](https://man7.org/linux/man-pages/man1/top.1.html)
- [procps package](https://gitlab.com/procps-ng/procps)