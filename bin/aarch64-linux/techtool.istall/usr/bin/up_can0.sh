
sudo ip link set can0 up type can bitrate 500000
sudo ip link set up can0
sudo ip link set can0 type can restart-ms 1
sudo ip -details link show can0



