#!/usr/bin/env bash

################################################################################
# System Monitoring Module
# Description: Provides system monitoring and health check functionality
# Commands: memory, processes, help
################################################################################

# Color codes
readonly C_RST='\033[0m' C_B='\033[1m' C_G='\033[0;32m' C_Y='\033[0;33m' C_R='\033[0;31m' C_C='\033[0;36m'

system_help() {
    cat <<EOF
${C_B}System Monitoring Module${C_RST}

Usage: lsm system <command> [options]

Commands:
  memory      - Display current memory and swap usage
  processes   - Monitor top processes in real-time(CPU%%, memory%%, command)
  processes   - List all running processes
  help        - Show this help message

Options:
  -s, --sort  Sort processes by 'cpu' or 'memory'

Examples:
  lsm system memory
  lsm system processes
  lsm system processes --refresh 2
  lsm system processes --count 15
  lsm system processes --sort cpu
  lsm system help

Process Monitoring Options:
  --refresh N    - Refresh interval in seconds (default: 3)
  --count N      - Number of processes to display (default: 10)
  --sort cpu     - Sort by CPU usage (default)
  --sort mem     - Sort by memory usage

EOF
}

# Calculate percentage: $1=used, $2=total
_calc_pct() {
    [[ -z "$2" || "$2" == "0" ]] && echo "0" && return
    awk -v u="$1" -v t="$2" 'BEGIN { printf "%.0f", (u * 100) / t }'
}

# Convert KB to human-readable: $1=size in KB
_kb_human() {
    [[ -z "$1" || "$1" == "0" ]] && echo "0 B" && return
    awk -v kb="$1" 'BEGIN {
        if (kb >= 1048576) printf "%.1f GB", kb/1048576
        else if (kb >= 1024) printf "%.1f MB", kb/1024
        else printf "%d KB", kb
    }'
}

# Get color based on percentage: $1=percentage
_get_color() {
    (( $1 >= 90 )) && echo -e "$C_R" && return
    (( $1 >= 75 )) && echo -e "$C_Y" && return
    echo -e "$C_G"
}

# Display memory report: $1=mem_total $2=mem_used $3=mem_free $4=mem_avail $5=swap_total $6=swap_used $7=swap_free
_display_report() {
    local mem_pct=$(_calc_pct "$2" "$1")
    local swap_pct=$(_calc_pct "$6" "$5")
    
    echo -e "${C_B}${C_C}Memory Usage Report${C_RST}\n${C_C}===================${C_RST}\n"
    echo -e "${C_B}Memory:${C_RST}"
    echo "  Total:     $(_kb_human "$1")"
    echo "  Used:      $(_kb_human "$2")"
    echo "  Free:      $(_kb_human "$3")"
    echo "  Available: $(_kb_human "$4")"
    echo -e "  Usage:     $(_get_color "$mem_pct")${mem_pct}%${C_RST}\n"
    
    echo -e "${C_B}Swap:${C_RST}"
    if [[ "$5" -gt 0 ]]; then
        echo "  Total:     $(_kb_human "$5")"
        echo "  Used:      $(_kb_human "$6")"
        echo "  Free:      $(_kb_human "$7")"
        echo -e "  Usage:     $(_get_color "$swap_pct")${swap_pct}%${C_RST}"
    else
        echo "  No swap configured"
    fi
}

system_memory() {
    local mem_total mem_used mem_free mem_avail swap_total swap_used swap_free
    
    # Try free command first
    if command -v free &> /dev/null; then
        local output=$(free -k 2>&1) || {
            # Try /proc/meminfo fallback
            [[ ! -r /proc/meminfo ]] && echo "Error: Cannot read /proc/meminfo" >&2 && return 1
            
            mem_total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
            mem_free=$(awk '/^MemFree:/ {print $2}' /proc/meminfo)
            mem_avail=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
            swap_total=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
            swap_free=$(awk '/^SwapFree:/ {print $2}' /proc/meminfo)
            
            [[ -z "$mem_total" ]] && echo "Error: Failed to parse memory info" >&2 && return 1
            
            mem_used=$((mem_total - mem_free))
            swap_used=$((swap_total - swap_free))
            [[ -z "$mem_avail" ]] && mem_avail="$mem_free"
            
            _display_report "$mem_total" "$mem_used" "$mem_free" "$mem_avail" "$swap_total" "$swap_used" "$swap_free"
            return 0
        }
        
        read -r _ mem_total mem_used mem_free _ _ mem_avail < <(echo "$output" | awk 'NR==2')
        read -r _ swap_total swap_used swap_free < <(echo "$output" | awk 'NR==3')
        
        [[ -z "$mem_total" ]] && echo "Error: Failed to parse free output" >&2 && return 1
        
        _display_report "$mem_total" "$mem_used" "$mem_free" "$mem_avail" "$swap_total" "$swap_used" "$swap_free"
        return 0
    fi
    
    # Fallback to /proc/meminfo if free not available
    [[ ! -r /proc/meminfo ]] && echo "Error: Cannot read /proc/meminfo" >&2 && return 1
    
    mem_total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    mem_free=$(awk '/^MemFree:/ {print $2}' /proc/meminfo)
    mem_avail=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
    swap_total=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
    swap_free=$(awk '/^SwapFree:/ {print $2}' /proc/meminfo)
    
    [[ -z "$mem_total" ]] && echo "Error: Failed to parse memory info" >&2 && return 1
    
    mem_used=$((mem_total - mem_free))
    swap_used=$((swap_total - swap_free))
    [[ -z "$mem_avail" ]] && mem_avail="$mem_free"
    
    _display_report "$mem_total" "$mem_used" "$mem_free" "$mem_avail" "$swap_total" "$swap_used" "$swap_free"
}

# Clear screen and reset cursor
_clear_screen() {
    printf '\033[2J\033[H'
}

# Get terminal dimensions
_get_terminal_size() {
    local rows cols
    if command -v tput &> /dev/null && [[ -n "$TERM" ]]; then
        rows=$(tput lines 2>/dev/null) || rows=${LINES:-24}
        cols=$(tput cols 2>/dev/null) || cols=${COLUMNS:-80}
    else
        rows=${LINES:-24}
        cols=${COLUMNS:-80}
    fi
    echo "$rows $cols"
}

# Handle terminal resize signal
_handle_resize() {
    TERM_RESIZED=1
}

# Display process header
_display_process_header() {
    local cols="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${C_B}${C_C}Top Processes Monitor${C_RST}"
    echo -e "${C_C}$(printf '=%.0s' $(seq 1 $((cols < 80 ? cols : 80))))${C_RST}"
    echo -e "Last updated: ${timestamp}"
    echo -e "Press ${C_B}Ctrl+C${C_RST} to exit\n"
    
    printf "${C_B}%-7s %-6s %-6s %-8s %-s${C_RST}\n" "PID" "CPU%" "MEM%" "USER" "COMMAND"
    printf '%*s\n' "$((cols < 80 ? cols : 80))" '' | tr ' ' '-'
}

# Parse and display processes using ps
_display_processes_ps() {
    local count="$1"
    local sort_key="$2"
    local cols="$3"
    
    # Determine sort field: 3=CPU%, 4=MEM%
    local sort_field=3
    [[ "$sort_key" == "mem" ]] && sort_field=4
    
    # Get process info and sort
    ps aux --sort=-pcpu 2>/dev/null | awk -v count="$count" -v sort_field="$sort_field" -v cols="$cols" '
    NR > 1 {
        pid = $2
        cpu = $3
        mem = $4
        user = $1
        
        # Extract command (everything from field 11 onwards)
        cmd = ""
        for (i = 11; i <= NF; i++) {
            cmd = cmd $i " "
        }
        
        # Truncate command to fit terminal
        max_cmd_len = cols - 35
        if (length(cmd) > max_cmd_len && max_cmd_len > 0) {
            cmd = substr(cmd, 1, max_cmd_len - 3) "..."
        }
        
        printf "%-7s %-6.1f %-6.1f %-8s %s\n", pid, cpu, mem, user, cmd
    }
    ' | head -n "$count"
}

# Display processes using top batch mode (fallback)
_display_processes_top() {
    local count="$1"
    local sort_key="$2"
    
    # Use top in batch mode
    if command -v top &> /dev/null; then
        # Different top versions have different flags
        if top -v 2>&1 | grep -q "procps-ng"; then
            # procps-ng version (most common)
            top -b -n 1 -o "%CPU" 2>/dev/null | awk -v count="$count" '
            /^[[:space:]]*[0-9]/ && NR > 7 {
                printf "%-7s %-6s %-6s %-8s %s\n", $1, $9, $10, $2, $12
            }
            ' | head -n "$count"
        else
            # Fallback to basic top output
            top -b -n 1 2>/dev/null | grep -v "^$" | tail -n +8 | head -n "$count"
        fi
    else
        echo "Error: Neither ps nor top commands are available" >&2
        return 1
    fi
}

# Main process monitoring function
system_processes() {
    local refresh_interval=3
    local process_count=10
    local sort_by="cpu"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --refresh)
                refresh_interval="$2"
                shift 2
                ;;
            --count)
                process_count="$2"
                shift 2
                ;;
            --sort)
                sort_by="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                echo "Use 'lsm system help' for usage information" >&2
                return 1
                ;;
        esac
    done
    
    # Validate inputs
    if ! [[ "$refresh_interval" =~ ^[0-9]+$ ]] || [[ "$refresh_interval" -lt 1 ]]; then
        echo "Error: Refresh interval must be a positive integer" >&2
        return 1
    fi
    
    if ! [[ "$process_count" =~ ^[0-9]+$ ]] || [[ "$process_count" -lt 1 ]]; then
        echo "Error: Process count must be a positive integer" >&2
        return 1
    fi
    
    if [[ "$sort_by" != "cpu" && "$sort_by" != "mem" ]]; then
        echo "Error: Sort option must be 'cpu' or 'mem'" >&2
        return 1
    fi
    
    # Check for required commands
    if ! command -v ps &> /dev/null && ! command -v top &> /dev/null; then
        echo "Error: Neither 'ps' nor 'top' command is available" >&2
        return 1
    fi
    
    # Set up terminal resize handler
    TERM_RESIZED=0
    trap _handle_resize WINCH
    
    # Main monitoring loop
    while true; do
        # Get terminal size
        read -r rows cols < <(_get_terminal_size)
        
        # Clear screen
        _clear_screen
        
        # Display header
        _display_process_header "$cols"
        
        # Display processes
        if command -v ps &> /dev/null; then
            _display_processes_ps "$process_count" "$sort_by" "$cols"
        else
            _display_processes_top "$process_count" "$sort_by"
        fi
        
        # Display footer
        echo ""
        echo -e "${C_B}Refresh interval:${C_RST} ${refresh_interval}s | ${C_B}Processes:${C_RST} ${process_count} | ${C_B}Sort:${C_RST} ${sort_by}"
        
        # Reset resize flag
        TERM_RESIZED=0
        
        # Sleep with interrupt handling
        sleep "$refresh_interval" &
        wait $! 2>/dev/null
        
        # Check if interrupted
        if [[ $? -ne 0 ]]; then
            break
        fi
    done
    
    # Cleanup
    trap - WINCH
    echo -e "\n${C_G}Process monitoring stopped.${C_RST}"

    local sort_by=""
    if [[ "${1:-}" == "--sort" || "${1:-}" == "-s" ]]; then
        sort_by="$2"
        shift 2
    fi

    echo -e "${C_B}${C_C}Running Processes${C_RST}\n${C_C}=================${C_RST}\n"

    local ps_cmd="ps aux"
    local head_cmd="head -n 20"
    
    case "$sort_by" in
        cpu)
            ps_cmd+=" --sort=-%cpu"
            ;;
        memory|mem)
            ps_cmd+=" --sort=-%mem"
            ;;
        "")
            # No sorting, default behavior
            ;;
        *)
            echo "Error: Invalid sort option. Use 'cpu' or 'memory'." >&2
            return 1
            ;;
    esac

    # Display header
    $ps_cmd | head -n 1

    # Display processes
    $ps_cmd | tail -n +2 | $head_cmd
}
