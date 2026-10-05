#!/bin/bash

# Get the status of the CAN interface
can_status=$(sudo ip -details link show can0)

# Check if the CAN interface is in ERROR-ACTIVE state
if echo "$can_status" | grep -q "can state ERROR-ACTIVE"; then
    # If active, run candump
    echo "candump can0"
    candump can0
else
    # If not active, display a message
    echo "CAN0 is not in ACTIVE state."
fi
