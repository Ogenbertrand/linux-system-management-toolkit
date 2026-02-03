#!/usr/bin/env bash

################################################################################
# System Module
# 
# Description: Provides system-level information and statistics.
# Commands: uptime
################################################################################

# Module help
system_help() {
    cat << EOF
System Module

Usage: lsm system <command> [options]

Commands:
  uptime      - Display total system uptime and last reboot time

Options:
  -h, --help  Show this help message

Examples:
  lsm system uptime
EOF
}

# Command: Uptime
system_uptime() {
    echo "--- System Uptime Information ---"

    # Get uptime using uptime -p for a more human-readable format
    UPTIME_OUTPUT=$(uptime -p 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$UPTIME_OUTPUT" ]; then
        echo "Total Uptime: ${UPTIME_OUTPUT#up }"
    else
        # Fallback for systems where uptime -p might not be available
        UPTIME_SECONDS=$(cut -d. -f1 /proc/uptime)
        
        DAYS=$((UPTIME_SECONDS / 60 / 60 / 24))
        HOURS=$((UPTIME_SECONDS / 60 / 60 % 24))
        MINUTES=$((UPTIME_SECONDS / 60 % 60))

        echo "Total Uptime: ${DAYS} days, ${HOURS} hours, ${MINUTES} minutes"
    fi

    # Get last reboot timestamp (e.g., Thu Jan 8 10:42)
    # This pulls columns 4, 5, 6, and 7 from the 'last reboot' command
    # We use 'awk' to find where the day of the week starts (e.g., "Thu") 
# and print from there to the end of the line.
LAST_REBOOT=$(last reboot | head -n 1 | awk '{for(i=1;i<=NF;i++) if($i ~ /^(Mon|Tue|Wed|Thu|Fri|Sat|Sun)$/) {for(j=i;j<=i+3;j++) printf "%s ", $j; break}}')
    if [ -n "$LAST_REBOOT" ]; then
        echo "Last Reboot: ${LAST_REBOOT}"
    else
        echo "Last Reboot: Not available"
    fi
}

# Main module function
system_main() {
    # Changed default from "help" to "uptime" so it runs immediately
    local command="${1:-uptime}"
    shift || true
    
    case "$command" in
        uptime)
            system_uptime "$@"
            ;;
        -h|--help|help)
            system_help
            ;;
        *)
            echo "Unknown command: $command"
            system_help
            exit 1
            ;;
    esac
}

# Execute main function
system_main "$@"