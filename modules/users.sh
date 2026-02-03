#!/usr/bin/env bash

# Active Users Listing Module
# Lists currently logged-in users with detailed information

users_list() {
    local filter_user="$1"

    echo "-----------------------------------------------"
    echo "LSM Toolkit: Active Users Listing"
    echo "-----------------------------------------------"
    printf "%-10s | %-10s | %-18s | %s\n" "Username" "Terminal" "Login Time" "Host"
    echo "-----------------------------------------------"

    # Get raw sessions
    local raw_sessions
    raw_sessions=$(who)

    # Filter if necessary
    local filtered_sessions
    if [[ -n "$filter_user" ]]; then
        filtered_sessions=$(echo "$raw_sessions" | awk -v u="$filter_user" '$1 == u')
    else
        filtered_sessions="$raw_sessions"
    fi

    if [[ -n "$filtered_sessions" ]]; then
        echo "$filtered_sessions" | awk '{
            host = $5; if (host == "") host = "-";
            printf "%-10s | %-10s | %-18s | %s\n", $1, $2, $3" "$4, host
        }'
    else
        if [[ -n "$filter_user" ]]; then
            echo "No active sessions found for user: $filter_user"
        else
            echo "No active sessions found."
        fi
    fi

    local count
    if [[ -z "$filtered_sessions" ]]; then
        count=0
    else
        count=$(echo "$filtered_sessions" | wc -l)
    fi

    echo ""
    echo "-----------------------------------------------"
    echo "Total active sessions: $count"
    echo "-----------------------------------------------"
}

users_groups() {
    echo "-----------------------------------------------"
    echo "LSM Toolkit: User Group Membership Audit"
    echo "-----------------------------------------------"
    printf "%-20s | %s\n" "Username" "Groups"
    echo "-----------------------------------------------"

    while IFS=: read -r user _ _ _ _ _ _; do
        groups=$(id -nG "$user" 2>/dev/null)
        if [[ -n "$groups" ]]; then
            printf "%-20s | %s\n" "$user" "$groups"
        fi
    done < /etc/passwd

    echo "-----------------------------------------------"
}

users_help() {
    echo "LSM Toolkit: Users Module"
    echo ""
    echo "Usage: lsm-toolkit users <command> [options]"
    echo ""
    echo "Commands:"
    echo "  list [username]    - List all active users or filter by username"
    echo "  groups             - List all users and their group memberships"
    echo "  help               - Show this help message"
    echo ""
    echo "Examples:"
    echo "  lsm-toolkit users list                    # List all active users"
    echo "  lsm-toolkit users list john              # Show only john's sessions"
    echo "  lsm-toolkit users groups                  # Audit all user group memberships"
    echo ""
    echo "Output includes: username, terminal, login time, host"
}
