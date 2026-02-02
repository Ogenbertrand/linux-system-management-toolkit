#!/bin/bash

# Display Operating System
echo "Operating System: $(uname -o)"

# Display Kernel Version
echo "Kernel Version: $(uname -r)"

# Display CPU Architecture
echo "CPU Architecture: $(uname -m)"

# Display System Uptime
echo "System Uptime: $(uptime -p)"
