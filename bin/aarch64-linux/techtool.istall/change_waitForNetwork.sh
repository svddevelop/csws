#!/bin/bash

#sudo apt install -y dhcpcd


# Path to the file
FILE="/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service"

# New content to write to the file
NEW_CONTENT="
[Unit]
Description=Network Manager Wait Online
Documentation=man:nm-online(1)
Requires=NetworkManager.service
After=NetworkManager.service
Before=network-online.target

[Service]
# `nm-online -s` waits until the point when NetworkManager logs
# 'startup complete'. That is when startup actions are settled and
# devices and profiles reached a conclusive activated or deactivated
# state. It depends on which profiles are configured to autoconnect and
# also depends on profile settings like ipv4.may-fail/ipv6.may-fail,
# which affect when a profile is considered fully activated.
# Check NetworkManager logs to find out why wait-online takes a certain
# time.

Type=oneshot
ExecStart=/usr/bin/nm-online -s -q --timeout=1
RemainAfterExit=yes

# Set $NM_ONLINE_TIMEOUT variable for timeout in seconds.
# Edit with `systemctl edit NetworkManager-wait-online`.
#
# Note, this timeout should commonly not be reached. If your boot
# gets delayed too long, then the solution is usually not to decrease
# the timeout, but to fix your setup so that the connected state
# gets reached earlier.
Environment=NM_ONLINE_TIMEOUT=60

[Install]
WantedBy=network-online.target

"
touch $FILE
# Check if the file exists
if [ -f "$FILE" ]; then
    # Overwrite the file with new content
    echo "$NEW_CONTENT" > "$FILE"
    sudo groupadd can
    sudo adduser technik can
    echo "File $FILE has been successfully updated."
else
    echo "File $FILE not found."
    exit 1
fi
