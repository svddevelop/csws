mkdir -p /var/techtool/thtml
cp -f -r ./var_thtml/*  /var/techtool/thtml/
chmod +x /var/techtool/thtml/wifi/connect_wifi.sh

systemctl stop csws.service
cp ./csws /usr/bin/
systemctl start csws.service

