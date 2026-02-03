#!/usr/bin/env bash

# Define Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "Running Unit Tests for Uptime Module..."
echo "===================================="

# Test: List Command
echo -n "[TEST] List Command: "
if lsm uptime list | grep -q "\-\-\- System Uptime Information \-\-\-"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# Test: Uptime Command
echo -n "[TEST] Uptime Command: "
if lsm uptime uptime | grep -q "Total Uptime:"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# Test: Help Command
echo -n "[TEST] Help Command: "
if lsm uptime help | grep -q "Usage: lsm uptime"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

echo "===================================="
echo "Final Command Output Check:"
lsm uptime list