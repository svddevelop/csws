#!/bin/bash

# Path to the file
FILE="/boot/firmware/config.txt"

# New content to write to the file
NEW_CONTENT="
gpio=8=op,dh
dtparam=spi=off
#dtoverlay=spi-bcm2835-overlay
#dtoverlay=spi0-1cs,cs0_pin=8
dtoverlay=spi0-1cs
#the parameter oscillator must have value ‘oscillator’ frequence * 2 !!!
dtoverlay=mcp2515-can0,spi0-0,oscillator=16000000,interrupt=25
#,bitrate=500000
dtoverlay=dwc2

"

# Check if the file exists
if [ -f "$FILE" ]; then
    # Overwrite the file with new content
    echo "$NEW_CONTENT" > "$FILE"
    echo "File $FILE has been successfully updated."
else
    echo "File $FILE not found."
    exit 1
fi
