#!/usr/bin/env bash

################################################################################
# Uptime Module
# 
# Description: Provides system uptime and reboot history.
# Commands: uptime, list, help
################################################################################

# Command: list
uptime_list() {
    echo "--- System Uptime Information ---"

    # Get human-readable uptime
    UPTIME_OUTPUT=$(uptime -p 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$UPTIME_OUTPUT" ]; then
        echo "Total Uptime: ${UPTIME_OUTPUT#up }"
    else
        # Fallback for systems where uptime -p is unavailable
        UPTIME_SECONDS=$(cut -d. -f1 /proc/uptime)
        DAYS=$((UPTIME_SECONDS / 60 / 60 / 24))
        HOURS=$((UPTIME_SECONDS / 60 / 60 % 24))
        MINUTES=$((UPTIME_SECONDS / 60 % 60))
        echo "Total Uptime: ${DAYS} days, ${HOURS} hours, ${MINUTES} minutes"
    fi

    # Get last reboot timestamp with dynamic date detection
    LAST_REBOOT=$(last reboot | head -n 1 | awk '{for(i=1;i<=NF;i++) if($i ~ /^(Mon|Tue|Wed|Thu|Fri|Sat|Sun)$/) {for(j=i;j<=i+3;j++) printf "%s ", $j; break}}')
    
    if [ -n "$LAST_REBOOT" ]; then
        echo "Last Reboot: ${LAST_REBOOT}"
    else
        echo "Last Reboot: Not available"
    fi
}

# Command: uptime (Maps to list)
uptime_uptime() {
    uptime_list
}

# Command: help
uptime_help() {
    cat << EOF
Uptime Module

Usage: lsm uptime <command> [options]

Commands:
  uptime      - Display total system uptime and last reboot time
  list        - Display total system uptime and last reboot time

Options:
  -h, --help  Show this help message

Examples:
  lsm uptime list
  lsm uptime help
EOF
}