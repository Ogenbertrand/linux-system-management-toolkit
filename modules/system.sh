#!/usr/bin/env bash

################################################################################
# System Monitoring Module
# Description: Provides system monitoring and health check functionality
# Commands: memory, help
################################################################################

# Color codes
readonly C_RST='\033[0m' C_B='\033[1m' C_G='\033[0;32m' C_Y='\033[0;33m' C_R='\033[0;31m' C_C='\033[0;36m'

system_help() {
    cat <<EOF
${C_B}System Monitoring Module${C_RST}

Usage: lsm system <command> [options]

Commands:
  memory      - Display current memory and swap usage
  processes   - List all running processes
  help        - Show this help message

Options:
  -s, --sort  Sort processes by 'cpu' or 'memory'

Examples:
  lsm system memory
  lsm system processes
  lsm system processes --sort cpu
  lsm system help

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

system_processes() {
    local sort_by=""
    if [[ "${1:-}" == "--sort" || "${1:-}" == "-s" ]]; then
        sort_by="$2"
        shift 2
    fi

    echo -e "${C_B}${C_C}Running Processes${C_RST}\n${C_C}=================${C_RST}\n"

    local ps_cmd="ps aux"
    local head_cmd="head -n 20"
    
    case "$sort_by" in
        memory|mem)
            ps_cmd+=" --sort=-%mem"
            ;;
        "")
            # No sorting, default behavior
            ;;
        *)
            echo "Error: Invalid sort option. Use 'memory'." >&2
            return 1
            ;;
    esac

    # Display header
    $ps_cmd | head -n 1

    # Display processes
    $ps_cmd | tail -n +2 | $head_cmd
}
