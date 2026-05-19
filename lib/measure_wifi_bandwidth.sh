#!/usr/bin/env bash
# measure_wifi_bandwidth.sh
# Tools and commands to measure the data transmitted over WiFi in the Multi-Robot System

echo "======================================================"
echo "   Multi-Robot WiFi Bandwidth Measurement Tools       "
echo "======================================================"

echo "
To measure total bandwidth through the WiFi interface:
1. Using iftop (per IP connection):
   sudo iftop -i <interface> (e.g., sudo iftop -i wlan0)
   -> Press 't' to change the display mode.
   -> Press 'P' to pause/resume.
   
2. Using nload (visual total bandwidth graph):
   nload <interface>
   
3. Using vnstat (historical traffic over time):
   vnstat -l -i <interface>  (live mode)

To measure bandwidth per process/port:
1. Using nethogs:
   sudo nethogs <interface>
   
2. Inspect open ports and network sockets:
   ss -tuanp

To measure ROS topic bandwidth (Local data vs Synchronized data):
1. Local raw ROS topic bandwidth:
   rostopic bw /velodyne_points
   rostopic bw /lio/odom
   rostopic bw /keyframe_vae

2. MOCHA Synchronized bandwidth metrics:
   MOCHA automatically tracks ZMQ bandwidth usage and bytes sent/received.
   It publishes this data on the following topics:
   rostopic echo /ddb/client_stats/jackal
   rostopic echo /ddb/client_stats/none_iris
   rostopic echo /ddb/client_stats/basestation
   
   To see the rate of the sync:
   rostopic hz /ddb/client_stats/jackal

To capture and analyze packets in detail:
1. tcpdump to pcap:
   sudo tcpdump -i <interface> -w mocha_traffic.pcap port 1234 or port 2234 or port 6234
2. Analyze in Wireshark:
   wireshark mocha_traffic.pcap
"

if ! command -v iftop &> /dev/null; then
    echo "[WARN] iftop is not installed. sudo apt install iftop"
fi

if ! command -v nload &> /dev/null; then
    echo "[WARN] nload is not installed. sudo apt install nload"
fi

if ! command -v nethogs &> /dev/null; then
    echo "[WARN] nethogs is not installed. sudo apt install nethogs"
fi
