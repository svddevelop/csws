#!/bin/bash

# Path to the file
FILE="/usr/bin/up_can0.sh"

# New content to write to the file
NEW_CONTENT="
sudo ip link set can0 up type can bitrate 500000
sudo ip link set up can0
sudo ip link set can0 type can restart-ms 1
sudo ip -details link show can0


"
touch $FILE

# Check if the file exists
if [ -f "$FILE" ]; then
    # Overwrite the file with new content
    echo "$NEW_CONTENT" > "$FILE"
    chmod +x $FILE
    echo "File $FILE has been successfully updated."
else
    echo "File $FILE not found."
    exit 1
fi
