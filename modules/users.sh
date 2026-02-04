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

    echo "$output" | while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if echo "$line" | grep -qE '^(reboot|shutdown|system boot|wtmp)'; then
            continue
        fi

        # The awk parsing block (your existing one) – but improve alignment a bit
        local parsed
        parsed=$(echo "$line" | awk '
                {
                    username = $1
                    tty      = $2
                    host     = (NF >= 3 && $3 != tty) ? $3 : "-"

                    # Build login time: start from field 4, collect until we see "-" "still" "down" etc.
                    login = ""
                    i = 4
                    while (i <= NF) {
                        token = $i
                        if (token == "-" || token == "still" || token == "down" || token == "crash" || token == "gone") break
                        login = (login == "" ? "" : login " ") token
                        i++
                    }

                    status = ""
                    logout = ""
                    duration = ""

                    if (token == "still") {
                        status = "still logged in"
                    } else if (token == "down") {
                        status = "down / reboot"
                    } else if (token == "crash") {
                        status = "crash / unclean"
                    } else if (token == "-") {
                        i++
                        logout_start = i
                        while (i <= NF && $i !~ /^\(/) {
                            i++
                        }
                        # Collect logout time fields
                        for (j = logout_start; j < i; j++) {
                            logout = (logout == "" ? "" : logout " ") $j
                        }
                        # Duration is usually the last field
                        if (i <= NF && $i ~ /^\(/) {
                            duration = substr($i, 2, length($i)-2)  # remove ( )
                        }
                    } else {
                        status = "(unknown)"
                    }

                    # Fallback: if duration not set and last field looks like duration
                    if (duration == "" && $NF ~ /^\(/) {
                        duration = substr($NF, 2, length($NF)-2)
                    }

                    print username "|" tty "|" host "|" login "|" (logout ? logout : status) "|" duration
                }')

        if [[ -n "$parsed" ]]; then
            # shellcheck disable=SC2046
            printf "%-12s | %-8s | %-18s | %-28s | %-28s | %s\n" $(echo "$parsed" | tr '|' ' ')
            ((printed++))
            (( printed >= max_count )) && break
        fi
    done

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
    echo "  history [username] [count] - Show recent login history (default: current user, 10 entries)"
    echo "  help              - Show this help message"
    echo ""
    echo "Examples:"
    echo "  lsm-toolkit users list                    # List all active users"
    echo "  lsm-toolkit users list john              # Show only john's sessions"
    echo "  lsm-toolkit users history                 # Last 10 logins of current user"
    echo "  lsm-toolkit users history alice 5         # Last 5 logins of alice"
    echo ""
    echo "Output includes: username, terminal, login time, host"
}
