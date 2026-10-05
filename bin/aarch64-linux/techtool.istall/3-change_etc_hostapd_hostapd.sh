#!/bin/bash

sudo apt install -y hostapd


# Path to the file
FILE="/etc/hostapd/hostapd.conf"

# New content to write to the file
NEW_CONTENT="
interface=wlan0
driver=nl80211
ssid=techtool
hw_mode=g
channel=7
wmm_enabled=1
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
"

RC_LOCAL="
#!/bin/sh

rfkill unblock wifi

# up the CAN network for SPI0.0
sudo ip link set can0 up type can bitrate 500000
sudo ip link set up can0
sudo ip link set can0 type can restart-ms 1

sudo ip -details link show can0
# ***
exit 0
"

DRC_LOCAL="
#! /bin/sh
### BEGIN INIT INFO
# Provides:          rc.local
# Required-Start:    $all
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-Description: Run /etc/rc.local if it exist
### END INIT INFO


PATH=/sbin:/usr/sbin:/bin:/usr/bin

. /lib/init/vars.sh
. /lib/lsb/init-functions

do_start() {
        if [ -x /etc/rc.local ]; then
                [ "$VERBOSE" != no ] && log_begin_msg \"Running local boot scripts (/etc/rc.local)\"
                /etc/rc.local
                ES=$?
                [ "$VERBOSE" != no ] && log_end_msg $ES
                return $ES
        fi
}

case "$1" in
    start)
        do_start
        ;;
    restart|reload|force-reload)
        echo \"Error: argument '$1' not supported\" >&2
        exit 3
        ;;
    stop)
        ;;
    *)
        echo \"Usage: $0 start|stop\" >&2
        exit 3
        ;;
esac
"


touch $FILE
# Check if the file exists
if [ -f "$FILE" ]; then
    # Overwrite the file with new content
    echo "$NEW_CONTENT" > "$FILE"
    echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' > "/etc/default/hostapd"
	
	touch /etc/rc.local
	chmod +x /etc/rc.local
	echo "$RC_LOCAL" > /etc/rc.local
	
	touch /etc/init.d/rc.local
	chmod +x /etc/init.d/rc.local
	echo "$DRC_LOCAL" > /etc/init.d/rc.local
	
	rfkill unblock wifi
	sudo systemctl disable NetworkManager
	sudo systemctl disable wpa_supplicant

    sudo systemctl unmask hostapd
    sudo systemctl enable hostapd

    sudo systemctl restart hostapd
    echo "File $FILE has been successfully updated."
	
	echo "for test of hostapd, run 'hostapd /etc/hostapd/hostapd.conf'"
else
    echo "File $FILE not found."
    exit 1
fi
