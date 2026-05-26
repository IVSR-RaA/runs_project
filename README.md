# run_mrm Runtime and Manual Debug Commands

`run_mrm.sh` starts runtime tasks only. It does not automatically start RViz,
rqt tools, `watch`, `roswtf`, or log-following panes. Use the commands below
from separate terminals when you need GUI or ROS inspection tools.

## Preconfig Virtual IP

Use this only for single-laptop simulation, where UAV, UGV, and base station
are faked as different loopback IP addresses on the same computer.

```bash
sudo ip addr add 10.249.171.1/24 dev lo
sudo ip addr add 10.229.222.1/24 dev lo
sudo ip addr add 10.229.221.1/24 dev lo
```

## Two-Laptop Distributed Setup

For real two-laptop distributed mode, do not use loopback aliases. Each laptop
must use its real WiFi/Ethernet IP, and both laptops must agree on the same
`UAV_IP` and `UGV_IP`.

Example network:

```text
UGV laptop IP: 192.168.1.21
UAV laptop IP: 192.168.1.22
```

Find each laptop IP:

```bash
ip -brief addr
ip route get 8.8.8.8
```

On the UGV laptop:

```bash
cd /home/nlg/all_ws
./run/run_mrm.sh --kill

MANAGE_LOOPBACK_ALIASES=false \
UGV_IP=192.168.1.21 \
UAV_IP=192.168.1.22 \
UGV_MASTER_URI=http://192.168.1.21:11312 \
UAV_MASTER_URI=http://192.168.1.22:11313 \
./run/run_mrm.sh --only ugv --distributed --no-attach
```

On the UAV laptop:

```bash
cd /home/nlg/all_ws
./run/run_mrm.sh --kill

MANAGE_LOOPBACK_ALIASES=false \
UGV_IP=192.168.1.21 \
UAV_IP=192.168.1.22 \
UGV_MASTER_URI=http://192.168.1.21:11312 \
UAV_MASTER_URI=http://192.168.1.22:11313 \
./run/run_mrm.sh --only uav --distributed --no-attach
```

Do not run `--only all` on both laptops. In this setup each laptop owns one
robot runtime. Distributed mode does not start the base-station runtime.

Keep Gazebo local unless you have a separate reason to share a Gazebo server:

```text
UGV laptop default: GAZEBO_MASTER_URI=http://127.0.0.1:11346
UAV laptop default: GAZEBO_MASTER_URI=http://127.0.0.1:11345
```

For a real robot run, the important network variables are:

```text
MANAGE_LOOPBACK_ALIASES=false
UGV_IP=<real UGV laptop IP>
UAV_IP=<real UAV laptop IP>
UGV_MASTER_URI=http://<real UGV laptop IP>:11312
UAV_MASTER_URI=http://<real UAV laptop IP>:11313
```

Both laptops must have the workspace built and sourced. They must also be able
to reach each other over the network:

```bash
ping 192.168.1.21
ping 192.168.1.22
```

Allow the MOCHA ports through the firewall, or disable the firewall during lab
testing:

```text
UGV MOCHA port: 2234
UAV MOCHA port: 6234
```

If using the older base-station topology too, also allow `1234`, `1235`,
`2235`, and `6235`.

Verify distributed sync on the UGV laptop:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://192.168.1.21:11312
export ROS_IP=192.168.1.21
rostopic hz /jackal/keyframe_vae /none_iris/keyframe_vae
rostopic hz /ugv1/lamp/keyed_scans /uav1/lamp/keyed_scans
rostopic echo -n1 /ugv1_fusion_base/lamp/octree_map/header
```

Verify distributed sync on the UAV laptop:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://192.168.1.22:11313
export ROS_IP=192.168.1.22
rostopic hz /none_iris/keyframe_vae /jackal/keyframe_vae
rostopic hz /uav1/lamp/keyed_scans /ugv1/lamp/keyed_scans
rostopic echo -n1 /uav1_fusion_base/lamp/octree_map/header
```

If you rename robots, use ROS-safe names. For example use `gazebo_tarot`, not
`gazebo-tarot`, for `UAV_MOCHA_ROBOT`. PX4/Gazebo model files can still contain
`-`; the ROS robot/topic names should not.

## Start and Stop Runtime

```bash
cd /home/nlg/all_ws
sudo -v
./run/run_mrm.sh --no-attach
```

```bash
cd /home/nlg/all_ws
sudo -v
./run/run_mrm.sh --distributed --no-attach
```

```bash
cd /home/nlg/all_ws
./run/run_mrm.sh --kill
```

## Distributed Map Names

In distributed mode, `/base1/lamp/octree_map` is not one shared ROS topic.
There are two ROS masters, so the same topic name can exist twice:

```text
UAV ROS master: /base1/lamp/octree_map relays /uav1_fusion_base/lamp/octree_map
UGV ROS master: /base1/lamp/octree_map relays /ugv1_fusion_base/lamp/octree_map
```

The `/base1/...` relays are compatibility aliases for RViz and older tooling.
They do not make the two distributed LAMP processes share one final map.

The two distributed maps should become similar only after both robot masters see
both robot LAMP inputs:

```text
UAV master must have: /uav1/lamp/keyed_scans and /ugv1/lamp/keyed_scans
UGV master must have: /uav1/lamp/keyed_scans and /ugv1/lamp/keyed_scans
```

Distributed mode now feeds local and remote LAMP inputs through the same
MOCHA-republished KeyframeVae decode path. Local `/keyframe_vae` is only the
producer-side input to MOCHA; LAMP consumes `/<robot>/keyframe_vae` for both
robots. This avoids comparing a local raw/direct map against a remote
MOCHA-decoded map. If either keyed-scan topic is missing on one master, that
master is still building a single-robot map and the final octree maps will look
different.

If you need one authoritative fused map, use base mode and view the base ROS
master:

```bash
cd /home/nlg/all_ws
./run/run_mrm.sh --no-attach
```

Then use the base debug environment and view `/base1/lamp/octree_map`.

To inspect what each distributed `/base1/lamp/octree_map` really is, run these
in separate terminals.

UAV master:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://10.249.171.1:11313
export ROS_IP=10.249.171.1
rostopic info /base1/lamp/octree_map
rostopic hz /uav1/lamp/keyed_scans /ugv1/lamp/keyed_scans
rostopic hz /uav1_fusion_base/lamp/octree_map /base1/lamp/octree_map
rostopic hz /none_iris/keyframe_vae /jackal/keyframe_vae
```

UGV master:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://10.229.222.1:11312
export ROS_IP=10.229.222.1
rostopic info /base1/lamp/octree_map
rostopic hz /uav1/lamp/keyed_scans /ugv1/lamp/keyed_scans
rostopic hz /ugv1_fusion_base/lamp/octree_map /base1/lamp/octree_map
rostopic hz /none_iris/keyframe_vae /jackal/keyframe_vae
```

If one master only receives its local robot keyframes, that map will look like a
single-robot map. Check MOCHA sync, RSSI, and `/ddb/client_stats/<robot>` before
expecting the two distributed maps to look similar.

Avoid leaving RViz or `rostopic hz` subscribed to `/base1/lamp/octree_map` for a
long time while diagnosing. LAMP can warn that the map publisher holds its
thread when heavy subscribers keep asking for the full 3D map.

## Runtime Tuning

Vehicle spawn positions are centralized in `run/lib/config.sh` and can be
overridden from the shell:

```bash
cd /home/nlg/all_ws
UGV_SPAWN_X=1 UGV_SPAWN_Y=0 UAV_SPAWN_X=0 UAV_SPAWN_Y=0 ./run/run_mrm.sh --distributed --no-attach
```

If Jackal appears in Gazebo but `spawn_model` reports a timeout, increase the
UGV spawn delay:

```bash
cd /home/nlg/all_ws
UGV_SPAWN_DELAY=12 ./run/run_mrm.sh --only ugv --no-attach
```

## UAV Debug Environment

Run this first in every UAV debug terminal:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://10.249.171.1:11313
export ROS_IP=10.249.171.1
export GAZEBO_MASTER_URI=http://127.0.0.1:11345
```

UAV GUI tools:

```bash
rviz -d /home/nlg/catkin1_ws/src/localizer_lamp/lamp/rviz/lamp_base.rviz
```

```bash
rqt_graph
```

```bash
rosrun rqt_tf_tree rqt_tf_tree
```

```bash
rqt_console
```

```bash
gzclient
```

UAV topic checks:

```bash
rostopic hz /keyframe_vae /uav1/lamp/keyed_scans /uav1_fusion_base/lamp/octree_map
```

```bash
rostopic echo -n1 /mavros/local_position/odom
```

```bash
rostopic echo -n1 /lio/odom
```

```bash
rostopic echo -n1 /uav1_fusion_base/lamp/octree_map/header
```

```bash
rosrun tf tf_monitor world uav1/lidar
```

## UGV Debug Environment

Run this first in every UGV debug terminal:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://10.229.222.1:11312
export ROS_IP=10.229.222.1
export GAZEBO_MASTER_URI=http://127.0.0.1:11346
```

UGV GUI tools:

```bash
rviz -d /home/nlg/catkin1_ws/src/localizer_lamp/lamp/rviz/lamp_base.rviz
```

```bash
rqt_graph
```

```bash
rosrun rqt_tf_tree rqt_tf_tree
```

```bash
rqt_console
```

```bash
gzclient
```

UGV topic checks:

```bash
rostopic hz /keyframe_vae /ugv1/lamp/keyed_scans /ugv1_fusion_base/lamp/octree_map
```

```bash
rostopic echo -n1 /lio/odom
```

```bash
rostopic echo -n1 /ugv1_fusion_base/lamp/octree_map/header
```

```bash
rosrun tf tf_monitor world ugv1/lidar
```

## Base Debug Environment

Run this first in every base debug terminal:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://10.229.221.1:11311
export ROS_IP=10.229.221.1
```

Base GUI tools:

```bash
rviz -d /home/nlg/catkin1_ws/src/localizer_lamp/lamp/rviz/lamp_base.rviz
```

```bash
rqt_graph
```

```bash
rosrun rqt_tf_tree rqt_tf_tree
```

```bash
rqt_console
```

Base topic checks:

```bash
rostopic hz /none_iris/keyframe_vae /jackal/keyframe_vae /base1/lamp/pose_graph /base1/lamp/octree_map
```

```bash
rostopic echo -n1 /base1/lamp/octree_map/header
```

```bash
rostopic echo -n1 /base1/pose_graph_visualizer/odometry_edges/header
```

## WiFi Payload Measurement

These commands are manual debug tools. They do not change the runtime.

First find the real WiFi interface name:

```bash
ip -brief link
iw dev
ip route get 8.8.8.8
```

Replace `wlp0s20f3` below with your WiFi interface.

Measure total bytes crossing the WiFi interface:

```bash
watch -n 1 "ip -s link show wlp0s20f3"
```

```bash
nload wlp0s20f3
```

Measure per-process or per-connection traffic:

```bash
sudo iftop -i wlp0s20f3
```

```bash
sudo nethogs wlp0s20f3
```

```bash
ss -tupn | grep -E '1234|1235|2234|2235|6234|6235'
```

Capture actual MOCHA/ZeroMQ packets on WiFi:

```bash
sudo tcpdump -i wlp0s20f3 -nn -tttt \
  'tcp port 1234 or tcp port 1235 or tcp port 2234 or tcp port 2235 or tcp port 6234 or tcp port 6235'
```

Save packets for Wireshark:

```bash
sudo tcpdump -i wlp0s20f3 -w mocha_payload.pcap \
  'tcp port 1234 or tcp port 1235 or tcp port 2234 or tcp port 2235 or tcp port 6234 or tcp port 6235'
```

For local simulation on one machine, use loopback instead of WiFi:

```bash
sudo tcpdump -i lo -nn -tttt \
  'tcp port 1234 or tcp port 1235 or tcp port 2234 or tcp port 2235 or tcp port 6234 or tcp port 6235'
```

Measure ROS topic payload before MOCHA synchronization. Run these on the
relevant ROS master:

```bash
rostopic bw /keyframe_vae
rostopic bw /none_iris/keyframe_vae
rostopic bw /jackal/keyframe_vae
rostopic bw /uav1/lamp/keyed_scans
rostopic bw /ugv1/lamp/keyed_scans
rostopic bw /base1/lamp/octree_map
```

Check MOCHA synchronized payload statistics. Use the matching debug environment
section above first, then run:

```bash
rostopic echo /ddb/client_stats/jackal
rostopic echo /ddb/client_stats/none_iris
rostopic echo /ddb/client_stats/basestation
```

```bash
rostopic hz /ddb/client_stats/jackal
rostopic hz /ddb/client_stats/none_iris
rostopic hz /ddb/client_stats/basestation
```

Useful fields in `/ddb/client_stats/<robot>`:

```text
answ_len: reply payload size in bytes
bw:       computed reply bandwidth
rtt:      request/reply round-trip time
msg:      MOCHA protocol message type
```

Interpretation:

```text
rostopic bw    = ROS publication payload on one ROS master
client_stats   = MOCHA synchronized payload/reply statistics
tcpdump/iftop  = actual bytes crossing the network interface
```

## Range Image Debug

After starting `range_image_visualizer.launch` or enabling the visualizer from a
runtime launch file, view the generated image topics:

```bash
rqt_image_view /range_image_viz/input_mono8
```

```bash
rqt_image_view /range_image_viz/output_mono8
```

```bash
rqt_image_view /range_image_viz/difference_mono8
```

## Notes About UAV Odometry

The UAV debug mapping path uses:

```text
odom:  /mavros/local_position/odom
cloud: /lio/cloud_body
```

This is intentional for the current PX4/Gazebo simulation. Super-LIO still
generates `/lio/odom` and `/lio/cloud_world`, but `/lio/odom` can become `nan`
after startup while `/mavros/local_position/odom` remains finite. That points to
Super-LIO estimator divergence in the UAV simulation path, not a Gazebo pose
failure. `/lio/cloud_world` is transformed using that Super-LIO odometry, so it
should be treated as a Super-LIO visualization/debug output, not as the LAMP
input in this fallback mode. LAMP receives body-frame scans from
`/lio/cloud_body` and poses from MAVROS local odometry.

The LAMP adapter filters non-finite XYZ points before publishing keyed scans.
This keeps LAMP from crashing if Super-LIO still emits a cloud containing
`nan`/`inf` points.

To test pure Super-LIO odometry anyway:

```bash
cd /home/nlg/all_ws
UAV_ODOM_TOPIC=/lio/odom ./run/run_mrm.sh --distributed --no-attach
```
