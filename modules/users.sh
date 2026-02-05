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

users_history() {
    local user="${1:-$(whoami)}"
    local max_count="${2:-10}"

    if ! [[ "$max_count" =~ ^[0-9]+$ ]] || (( max_count < 1 )); then
        echo "Error: Number of entries must be a positive integer." >&2
        return 1
    fi

    # Ask for slightly more than needed to account for skipped lines + footer
    local output
    output=$(last -F -n $((max_count + 12)) -- "$user" 2>/dev/null)

    # Count potential valid lines: non-empty, not starting with known noise
    local valid_count
    valid_count=$(echo "$output" | grep -vE '^(reboot|shutdown|system boot|wtmp|^$)' | wc -l)

    if (( valid_count == 0 )); then
        echo "-----------------------------------------------"
        echo "LSM Toolkit: Login History for $user"
        echo "-----------------------------------------------"
        echo "No login history found for user '$user'."
        echo "(No valid session records in /var/log/wtmp)"
        echo "-----------------------------------------------"
        return 0
    fi

    # ── Proceed only if we have valid entries ──
    echo "-----------------------------------------------"
    echo "LSM Toolkit: Login History for $user (up to $max_count entries)"
    echo "-----------------------------------------------"
    printf "%-12s | %-8s | %-18s | %-28s | %-28s | %s\n" \
        "Username" "TTY" "Host" "Login" "Logout / Status" "Duration"
    echo "-----------------------------------------------"

    local printed=0

    # Use process substitution to avoid subshell for printed variable
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if echo "$line" | grep -qE '^(reboot|shutdown|system boot|wtmp)'; then
            continue
        fi

        # Parse the line with awk
        local parsed
        parsed=$(echo "$line" | awk '{
            # Parse username and tty
            username = $1
            tty = $2

            # Parse host (field 3 might be host or sometimes empty)
            host = ""
            if (NF >= 3) {
                # Host field should not look like a tty or IP address pattern
                if ($3 != tty && $3 !~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
                    host = $3
                }
            }
            if (host == "") host = "-"

            # Find where login time starts (usually field 4)
            login_start = 4
            # If we have a host in field 3, login starts at 4, otherwise at 5
            if (host != "-") login_start = 5

            # Build login time string
            login = ""
            i = login_start
            while (i <= NF) {
                # Stop when we hit status indicators or logout separator
                if ($i == "-" || $i == "still" || $i == "down" || $i == "crash" || $i == "gone") {
                    break
                }
                login = login (login == "" ? "" : " ") $i
                i++
            }

            # Determine status or parse logout time
            status = ""
            logout = ""
            duration = ""

            if ($i == "still") {
                status = "still logged in"
                # Duration might be in next field or field after
                if (i+1 <= NF && $(i+1) ~ /^\(/) {
                    duration = substr($(i+1), 2, length($(i+1))-2)
                }
            } else if ($i == "down" || $i == "crash" || $i == "gone") {
                status = $i
                if (i+1 <= NF && $(i+1) ~ /^\(/) {
                    duration = substr($(i+1), 2, length($(i+1))-2)
                }
            } else if ($i == "-") {
                # Parse logout time
                i++
                logout_start = i
                while (i <= NF && $i !~ /^\(/) {
                    i++
                }
                # Collect logout time
                for (j = logout_start; j < i; j++) {
                    logout = logout (logout == "" ? "" : " ") $j
                }
                # Parse duration
                if (i <= NF && $i ~ /^\(/) {
                    duration = substr($i, 2, length($i)-2)
                }
            }

            # Output pipe-separated fields
            print username "|" tty "|" host "|" login "|" (logout ? logout : status) "|" duration
        }')

        if [[ -n "$parsed" ]]; then
            # Use printf with proper field splitting
            IFS='|' read -r username tty host login status duration <<< "$parsed"
            printf "%-12s | %-8s | %-18s | %-28s | %-28s | %s\n" \
                "$username" "$tty" "$host" "$login" "$status" "$duration"

            ((printed++))
            if (( printed >= max_count )); then
                break
            fi
        fi
    done < <(echo "$output")

    echo "-----------------------------------------------"
    echo "Shown $printed most recent valid entries"
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