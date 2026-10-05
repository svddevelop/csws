#!/bin/bash

# Path to the file
FILE="/etc/sysctl.comf"

if [ -f "$FILE" ]; then
	echo "."
else
    touch $FILE
fi

# Check if the file exists
if [ -f "$FILE" ]; then
    # Overwrite the file with new content
    echo "net.ipv4.ip_forward=1" >> "$FILE"
    sudo sysctl -p
    echo "File $FILE has been successfully updated."
else
    echo "File $FILE not found."
    exit 1
fi
