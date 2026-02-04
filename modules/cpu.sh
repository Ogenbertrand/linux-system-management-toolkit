#!/usr/bin/env bash

################################################################################
# CPU Monitoring Module
# Description: Provides CPU usage monitoring and statistics
# Commands: usage, help
################################################################################

# Color codes (duplicate locally for independence or assume sourced by main)
# The main script defines some, but for module independence it's safer to have them.
readonly C_RST='\033[0m' C_B='\033[1m' C_G='\033[0;32m' C_Y='\033[0;33m' C_R='\033[0;31m' C_C='\033[0;36m'

cpu_help() {
    cat <<EOF
${C_B}CPU Monitoring Module${C_RST}

Usage: lsm cpu <command> [options]

Commands:
  usage       - Display real-time CPU usage
  help        - Show this help message

Options:
  -a, --all   Show per-core CPU statistics
  [interval]  Optional refresh interval in seconds

Examples:
  lsm cpu usage
  lsm cpu usage 2
  lsm cpu usage --all
  lsm cpu help

EOF
}

_read_cpu_stats() {
    [[ ! -r /proc/stat ]] && return 1
    grep '^cpu' /proc/stat
}

_get_color() {
    local pct=$1
    (( pct >= 90 )) && echo -e "$C_R" && return
    (( pct >= 75 )) && echo -e "$C_Y" && return
    echo -e "$C_G"
}

_calculate_cpu_usage() {
    local prev_stats=($1)
    local curr_stats=($2)
    
    # Idle = idle + iowait
    local prev_idle=$((prev_stats[4] + prev_stats[5]))
    local curr_idle=$((curr_stats[4] + curr_stats[5]))
    
    local prev_total=0
    for i in "${prev_stats[@]:1}"; do prev_total=$((prev_total + i)); done
    
    local curr_total=0
    for i in "${curr_stats[@]:1}"; do curr_total=$((curr_total + i)); done
    
    local total_diff=$((curr_total - prev_total))
    local idle_diff=$((curr_idle - prev_idle))
    
    [[ $total_diff -eq 0 ]] && echo "0" && return
    
    local usage_pct=$(( (total_diff - idle_diff) * 100 / total_diff ))
    echo "$usage_pct"
}

cpu_usage() {
    local show_all=false
    local interval=0
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a|--all) show_all=true; shift ;;
            [0-9]*) interval="$1"; shift ;;
            *) shift ;;
        esac
    done

    while true; do
        local prev_stats
        prev_stats=$(_read_cpu_stats) || { echo "Error: Cannot read /proc/stat" >&2; return 1; }
        
        sleep 1
        
        local curr_stats
        curr_stats=$(_read_cpu_stats) || { echo "Error: Cannot read /proc/stat" >&2; return 1; }
        
        # Clear screen only if interval is set
        [[ "$interval" -gt 0 ]] && clear

        echo -e "${C_B}${C_C}CPU Usage Report${C_RST} ($(date '+%H:%M:%S'))"
        echo -e "${C_C}===================${C_RST}"

        # Total CPU
        local t_prev=($(echo "$prev_stats" | head -n 1))
        local t_curr=($(echo "$curr_stats" | head -n 1))
        local total_usage=$(_calculate_cpu_usage "${t_prev[*]}" "${t_curr[*]}")
        echo -ne "Total CPU: "
        echo -e "$(_get_color "$total_usage")${total_usage}%${C_RST}"

        if [[ "$show_all" == true ]]; then
            echo -e "\n${C_B}Per-Core Usage:${C_RST}"
            local prev_lines curr_lines
            mapfile -t prev_lines < <(echo "$prev_stats" | tail -n +2)
            mapfile -t curr_lines < <(echo "$curr_stats" | tail -n +2)
            
            for i in "${!prev_lines[@]}"; do
                [[ "${prev_lines[$i]}" != cpu[0-9]* ]] && continue
                local p_line=(${prev_lines[$i]})
                local c_line=(${curr_lines[$i]})
                local core_usage=$(_calculate_cpu_usage "${p_line[*]}" "${c_line[*]}")
                printf "  %-6s " "${p_line[0]}:"
                echo -e "$(_get_color "$core_usage")${core_usage}%${C_RST}"
            done
        fi

        [[ "$interval" -eq 0 ]] && break
        echo -e "\nRefreshing in ${interval}s... (Ctrl+C to stop)"
        sleep "$interval"
    done
}
