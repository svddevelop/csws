#!/bin/bash

cp ../web/csws /usr/bin/

SERVICE_NAME="csws.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"
APP_PATH="/usr/bin/csws"
USER_NAME="technik"
GROUP_NAME="technik"

if [ -f "$SERVICE_FILE" ]; then
    echo "Service file already exists. Aborting."
    exit 1
fi

echo "[Unit]
Description=Technik WEB service
After=network.target

[Service]
ExecStart=sudo $APP_PATH
ExecStop=curl -s -X POST \"http://127.0.0.1/stop\"
Restart=on-failure
User=$USER_NAME
Group=$GROUP_NAME

[Install]
WantedBy=multi-user.target" | sudo tee "$SERVICE_FILE" > /dev/null

sudo systemctl daemon-reload

sudo systemctl start "$SERVICE_NAME"

sudo systemctl enable "$SERVICE_NAME"

echo "Service '$SERVICE_NAME' has been created and started."
echo "To check the status, run: sudo systemctl status $SERVICE_NAME"
echo "To stop the service, run: sudo systemctl stop $SERVICE_NAME"
