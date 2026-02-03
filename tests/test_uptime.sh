#!/usr/bin/env bash

# Define the script under test
SCRIPT="$(dirname "$0")/../modules/uptime.sh"

# Colors for clarity
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Running Unit Tests for uptime.sh..."
echo "===================================="

# 1. Test: Help Menu (Template structure test)
echo -n "[TEST] Template Help Menu: "
if bash "$SCRIPT" --help | grep -q "Usage: lsm system"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC} (Help menu not found)"
fi

# 2. Test: Default Command (Main function test)
echo -n "[TEST] Default Execution: "
if bash "$SCRIPT" | grep -q "\-\-\- System Uptime Information \-\-\-"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC} (Header missing)"
fi

# 3. Test: Last Reboot Formatting
echo -n "[TEST] Reboot Format:     "
REBOOT_OUT=$(bash "$SCRIPT" | grep "Last Reboot:")
if [[ $REBOOT_OUT =~ Last\ Reboot:\ [A-Za-z]{3}\ [A-Za-z]{3}\ +[0-9]{1,2} ]]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC} (Format: $REBOOT_OUT)"
fi

# 4. Test: Logical Output Content
echo -n "[TEST] Content Presence:  "
if bash "$SCRIPT" | grep -q "Total Uptime:"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC} (Uptime label missing)"
fi

echo "===================================="
echo "Final Output Check:"
bash "$SCRIPT"