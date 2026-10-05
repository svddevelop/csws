#!/bin/bash

sudo apt install -y dhcpcd


# Path to the file
FILE="/etc/dhcpcd.conf"
FILEBKP="/etc/dhcpcd.conf.bkp"

# New content to write to the file
NEW_CONTENT="
interface wlan0
static ip_address=192.168.4.1/24
nohook wpa_supplicant
"

if [ -f "$FILE" ]; then
	if [ ! -f "$FILE" ]; then
		cp "$FILE" "$FILEBKP"
	fi
fi
if [ ! -f "$FILE" ]; then
	touch $FILE
fi

# Check if the file exists
if [ -f "$FILE" ]; then
    # Overwrite the file with new content
    echo "$NEW_CONTENT" >> "$FILE"
    sudo systemctl restart dhcpcd
    echo "File $FILE has been successfully updated."
else
    echo "File $FILE not found."
    exit 1
fi
