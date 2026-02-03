#!/usr/bin/env bash

################################################################################
# Standalone Test Script for Process Monitoring
# This script can be run directly without the full toolkit
################################################################################

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the system module
if [[ -f "$SCRIPT_DIR/system.sh" ]]; then
    source "$SCRIPT_DIR/system.sh"
else
    echo "Error: system.sh not found in $SCRIPT_DIR"
    echo "Please ensure system.sh is in the same directory as this script"
    exit 1
fi

# Display banner
cat << 'EOF'
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║     Process Monitoring - Standalone Test             ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝

EOF

echo "This script will run the process monitoring feature."
echo "Press Ctrl+C to exit at any time."
echo ""

# Parse command line arguments or use defaults
if [[ $# -eq 0 ]]; then
    echo "Running with default settings (3s refresh, 10 processes, CPU sort)"
    echo "Usage: $0 [--refresh N] [--count N] [--sort cpu|mem]"
    echo ""
    sleep 2
    system_processes
else
    echo "Running with your options: $@"
    echo ""
    sleep 1
    system_processes "$@"
fi