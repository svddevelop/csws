#!/bin/bash

sudo apt install -y dnsmasq


# Path to the file
FILE="/etc/dnsmasq.conf"

# New content to write to the file
NEW_CONTENT="
interface=wlan0
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h

"
touch $FILE
# Check if the file exists
if [ -f "$FILE" ]; then
    # Overwrite the file with new content
    echo "$NEW_CONTENT" > "$FILE"
    sudo systemctl restart dnsmasq
    echo "File $FILE has been successfully updated."
else
    echo "File $FILE not found."
    exit 1
fi
