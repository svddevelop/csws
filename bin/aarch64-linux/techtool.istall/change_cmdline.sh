#!/bin/bash

# Path to the file
FILE="/boot/firmware/cmdline.txt"

# New text to write to the file
NEW_TEXT="root=PARTUUID=838e696d-02 rootfstype=ext4 fsck.repair=yes rootwait modules-load=dwc2,g_ether systemd.restore_state=0 rfkill.default_state=1"

# Check if the file exists
if [ -f "$FILE" ]; then
    # Overwrite the file with new text
    echo "$NEW_TEXT" > "$FILE"
    echo "File $FILE has been successfully overwritten."
else
    echo "File $FILE not found."
    exit 1
fi
