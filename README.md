# run_mrm Runtime Guide

`run/run_mrm.sh` starts the runtime tmux session for simulation, MOCHA, VAE,
Super-LIO, LAMP, the UGV planner, and the UAV sequence controller. It does not
automatically start RViz, rqt tools, tcpdump, or other inspection tools. Use
the debug commands in this file from separate terminals when needed.

## Contents

- [Quick Start](#quick-start)
- [Runtime Modes](#runtime-modes)
- [Network Defaults](#network-defaults)
- [Single-Laptop Virtual IP Setup](#single-laptop-virtual-ip-setup)
- [Two-Laptop Distributed Setup](#two-laptop-distributed-setup)
- [Three-Laptop Centralized Setup](#three-laptop-centralized-setup)
- [Centralized Multi-Hop MOCHA](#centralized-multi-hop-mocha)
- [Final Map Topics](#final-map-topics)
- [RViz and Debug Tools](#rviz-and-debug-tools)
- [Runtime Tuning](#runtime-tuning)
- [UGV CMU Planner](#ugv-cmu-planner)
- [UAV PX4 Sequence Controller](#uav-px4-sequence-controller)
- [VAE Model Selection](#vae-model-selection)
- [WiFi Payload Measurement](#wifi-payload-measurement)
- [Range Image Debug](#range-image-debug)
- [Troubleshooting Notes](#troubleshooting-notes)

## Quick Start

Centralized/base-station mode:

```bash
cd /home/nlg/all_ws
sudo -v
./run/run_mrm.sh --no-attach
```

Distributed mode:

```bash
cd /home/nlg/all_ws
sudo -v
./run/run_mrm.sh --distributed --no-attach
```

Start only one runtime group:

```bash
cd /home/nlg/all_ws
./run/run_mrm.sh --only ugv --no-attach
./run/run_mrm.sh --only uav --no-attach
./run/run_mrm.sh --only base --no-attach
```

Attach or stop the runtime session:

```bash
tmux attach -t mrm-debug
```

```bash
cd /home/nlg/all_ws
./run/run_mrm.sh --kill
```

## Runtime Modes

| Command | Runtime groups | LAMP topology | Main map to inspect |
| --- | --- | --- | --- |
| `./run/run_mrm.sh --no-attach` | UAV, UGV, base | Centralized base aggregator | Base master `/base1/lamp/octree_map` |
| `./run/run_mrm.sh --distributed --no-attach` | UAV, UGV | One LAMP fusion process on each robot | UAV and UGV robot masters |
| `./run/run_mrm.sh --only ugv --no-attach` | UGV only | Centralized-compatible local runtime | UGV local topics |
| `./run/run_mrm.sh --only uav --no-attach` | UAV only | Centralized-compatible local runtime | UAV local topics |
| `./run/run_mrm.sh --only base --no-attach` | Base only | Centralized base aggregator | Base master topics |

`--only base` is not valid with `--distributed`. Distributed mode has no base
runtime; each robot runs its own local fusion LAMP.

## Network Defaults

These defaults live in `run/lib/config.sh`.

| Role | Default IP | ROS master | Gazebo master | MOCHA name | LAMP name |
| --- | --- | --- | --- | --- | --- |
| UAV | `10.249.171.1` | `http://10.249.171.1:11313` | `http://127.0.0.1:11345` | `none_iris` | `uav1` |
| UGV | `10.229.222.1` | `http://10.229.222.1:11312` | `http://127.0.0.1:11346` | `jackal` | `ugv1` |
| Base | `10.229.221.1` | `http://10.229.221.1:11311` | none | `basestation` | `base1` |

Keep UAV and UGV on different Gazebo masters. Sharing one Gazebo master while
using different ROS masters can mix `/gazebo` services and topic names.

Use ROS-safe names for robot topics. For example use `gazebo_tarot`, not
`gazebo-tarot`, for `UAV_MOCHA_ROBOT`. PX4/Gazebo model filenames can still
contain `-`; ROS graph names should not.

## Single-Laptop Virtual IP Setup

For single-laptop simulation, the default runtime uses loopback aliases so UAV,
UGV, and base look like separate machines:

```bash
sudo ip addr add 10.249.171.1/24 dev lo
sudo ip addr add 10.229.222.1/24 dev lo
sudo ip addr add 10.229.221.1/24 dev lo
```

`run_mrm.sh` can create missing aliases automatically when
`MANAGE_LOOPBACK_ALIASES=true`, which is the default. Run `sudo -v` first if you
want the script to start without a sudo prompt.

## Two-Laptop Distributed Setup

For a real two-laptop distributed run, do not use loopback aliases. Each laptop
must use its real WiFi/Ethernet IP, and both laptops must agree on `UAV_IP`,
`UGV_IP`, `UAV_MASTER_URI`, and `UGV_MASTER_URI`.

Example network:

```text
UGV laptop IP: 192.168.0.199
UAV laptop IP: 192.168.0.161
```

Find each laptop IP:

```bash
ip -brief addr
ip route get 8.8.8.8
```

Run on the UGV laptop:

```bash
cd /home/nlg/all_ws
./run/run_mrm.sh --kill

MANAGE_LOOPBACK_ALIASES=false \
UGV_IP=192.168.0.199 \
UAV_IP=192.168.0.161 \
UGV_MASTER_URI=http://192.168.0.199:11312 \
UAV_MASTER_URI=http://192.168.0.161:11313 \
./run/run_mrm.sh --only ugv --distributed --no-attach
```

Run on the UAV laptop:

```bash
cd /home/nlg/all_ws
./run/run_mrm.sh --kill

MANAGE_LOOPBACK_ALIASES=false \
UGV_IP=192.168.0.199 \
UAV_IP=192.168.0.161 \
UGV_MASTER_URI=http://192.168.0.199:11312 \
UAV_MASTER_URI=http://192.168.0.161:11313 \
./run/run_mrm.sh --only uav --distributed --no-attach
```

Do not run `--only all` on both laptops. Each laptop owns one robot runtime.

Allow MOCHA/ZeroMQ ports through the firewall:

| Role | Main port |
| --- | --- |
| Base | `1234` |
| UGV | `2234` |
| UAV | `6234` |

If using the older base-station topology too, also allow `1235`, `2235`, and
`6235`.

Verify the UGV laptop:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://192.168.0.199:11312
export ROS_IP=192.168.0.199
rostopic hz /jackal/keyframe_vae /none_iris/keyframe_vae
rostopic hz /ugv1/lamp/keyed_scans /uav1/lamp/keyed_scans
rostopic echo -n1 /ugv1_fusion_base/lamp/octree_map/header
```

Verify the UAV laptop:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://192.168.0.161:11313
export ROS_IP=192.168.0.161
rostopic hz /none_iris/keyframe_vae /jackal/keyframe_vae
rostopic hz /uav1/lamp/keyed_scans /ugv1/lamp/keyed_scans
rostopic echo -n1 /uav1_fusion_base/lamp/octree_map/header
```

## Three-Laptop Centralized Setup

For a real centralized run with three laptops, keep the same UGV and UAV IPs as
the distributed example and add one base-station laptop. Do not use loopback
aliases.

Example network:

```text
Base laptop IP: 192.168.0.150
UGV laptop IP:  192.168.0.199
UAV laptop IP:  192.168.0.161
```

All three laptops must use the same values for `BASE_IP`, `UGV_IP`, `UAV_IP`,
`BASE_MASTER_URI`, `UGV_MASTER_URI`, and `UAV_MASTER_URI`.

Run on the base laptop:

```bash
cd /home/nlg/all_ws
./run/run_mrm.sh --kill

MANAGE_LOOPBACK_ALIASES=false \
BASE_IP=192.168.0.150 \
UGV_IP=192.168.0.199 \
UAV_IP=192.168.0.161 \
BASE_MASTER_URI=http://192.168.0.150:11311 \
UGV_MASTER_URI=http://192.168.0.199:11312 \
UAV_MASTER_URI=http://192.168.0.161:11313 \
./run/run_mrm.sh --only base --no-attach
```

Run on the UGV laptop:

```bash
cd /home/nlg/all_ws
./run/run_mrm.sh --kill

MANAGE_LOOPBACK_ALIASES=false \
BASE_IP=192.168.0.150 \
UGV_IP=192.168.0.199 \
UAV_IP=192.168.0.161 \
BASE_MASTER_URI=http://192.168.0.150:11311 \
UGV_MASTER_URI=http://192.168.0.199:11312 \
UAV_MASTER_URI=http://192.168.0.161:11313 \
./run/run_mrm.sh --only ugv --no-attach
```

Run on the UAV laptop:

```bash
cd /home/nlg/all_ws
./run/run_mrm.sh --kill

MANAGE_LOOPBACK_ALIASES=false \
BASE_IP=192.168.0.150 \
UGV_IP=192.168.0.199 \
UAV_IP=192.168.0.161 \
BASE_MASTER_URI=http://192.168.0.150:11311 \
UGV_MASTER_URI=http://192.168.0.199:11312 \
UAV_MASTER_URI=http://192.168.0.161:11313 \
./run/run_mrm.sh --only uav --no-attach
```

This is centralized mode because the final fused map is produced by LAMP on the
base ROS master:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://192.168.0.150:11311
export ROS_IP=192.168.0.150
rostopic hz /jackal/keyframe_vae /none_iris/keyframe_vae /base1/lamp/octree_map
rostopic echo -n1 /base1/lamp/octree_map/header
```

The default centralized MOCHA config generated by `run_mrm.sh` is full mesh:
base talks to both robots, and the two robots can also talk to each other. If
you want strict base-only communication, create this file on all three laptops:

```yaml
basestation:
  node-type: "base_station"
  IP-address: "192.168.0.150"
  using-radio: "radio_base"
  base-port: "1234"
  clients:
    - "jackal"
    - "none_iris"

jackal:
  node-type: "ground_robot"
  IP-address: "192.168.0.199"
  using-radio: "radio_ugv"
  base-port: "2234"
  clients:
    - "basestation"

none_iris:
  node-type: "aerial_robot"
  IP-address: "192.168.0.161"
  using-radio: "radio_uav"
  base-port: "6234"
  clients:
    - "basestation"
```

Then add the same `MOCHA_ROBOT_CONFIG` value to all three start commands:

```bash
MOCHA_ROBOT_CONFIG=/home/nlg/all_ws/run/mocha_three_laptop_central.yaml
```

Open these ports between the laptops:

| Laptop | Port |
| --- | --- |
| Base | `1234` |
| UGV | `2234` |
| UAV | `6234` |

## Centralized Multi-Hop MOCHA

Default centralized mode is a base-station aggregator. The base receives both
robot keyframes and decodes them into one base LAMP map.

If the UGV cannot reach the base directly but can reach the UAV, configure
MOCHA as a relay path:

```text
jackal <-> none_iris <-> basestation
```

Use a custom robot config, for example:

```yaml
basestation:
  node-type: "base_station"
  IP-address: "10.229.221.1"
  using-radio: "radio_base"
  base-port: "1234"
  clients:
    - "none_iris"
jackal:
  node-type: "ground_robot"
  IP-address: "10.229.222.1"
  using-radio: "radio_ugv"
  base-port: "2234"
  clients:
    - "none_iris"
none_iris:
  node-type: "aerial_robot"
  IP-address: "10.249.171.1"
  using-radio: "radio_uav"
  base-port: "6234"
  clients:
    - "jackal"
    - "basestation"
```

Then start centralized mode with that config:

```bash
cd /home/nlg/all_ws
MOCHA_ROBOT_CONFIG=/tmp/mocha_multihop_robot_configs.yaml ./run/run_mrm.sh --no-attach
```

The base should eventually receive `/jackal/keyframe_vae` through the UAV's
MOCHA database sync. This is still centralized LAMP because the final fused map
is produced on the base ROS master.

## Final Map Topics

Centralized/base mode has one authoritative final map:

```text
ROS master:  http://10.229.221.1:11311
Final map:   /base1/lamp/octree_map
```

Distributed mode has one fusion LAMP per robot master:

| ROS master | Real distributed map | Compatibility alias |
| --- | --- | --- |
| UAV master | `/uav1_fusion_base/lamp/octree_map` | `/base1/lamp/octree_map` |
| UGV master | `/ugv1_fusion_base/lamp/octree_map` | `/base1/lamp/octree_map` |

In distributed mode, `/base1/lamp/octree_map` is not one shared topic. The same
topic name exists separately on the UAV ROS master and on the UGV ROS master.
The two maps should become similar only after both masters receive both robots'
decoded keyed scans:

```text
/uav1/lamp/keyed_scans
/ugv1/lamp/keyed_scans
```

If one master only receives its local robot keyed scans, that master is building
a single-robot map.

Check distributed map inputs on the UAV master:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://10.249.171.1:11313
export ROS_IP=10.249.171.1
rostopic hz /uav1/lamp/keyed_scans /ugv1/lamp/keyed_scans
rostopic hz /uav1_fusion_base/lamp/octree_map /base1/lamp/octree_map
rostopic hz /none_iris/keyframe_vae /jackal/keyframe_vae
```

Check distributed map inputs on the UGV master:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://10.229.222.1:11312
export ROS_IP=10.229.222.1
rostopic hz /uav1/lamp/keyed_scans /ugv1/lamp/keyed_scans
rostopic hz /ugv1_fusion_base/lamp/octree_map /base1/lamp/octree_map
rostopic hz /none_iris/keyframe_vae /jackal/keyframe_vae
```

Avoid leaving RViz subscribed to the full octree map for a long time while
diagnosing. Heavy subscribers can make LAMP warn that its map publisher is
holding a thread.

## RViz and Debug Tools

Use one debug terminal per robot/master. Source the matching environment first,
then start GUI tools or topic checks.

UAV debug environment:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://10.249.171.1:11313
export ROS_IP=10.249.171.1
export GAZEBO_MASTER_URI=http://127.0.0.1:11345
```

UGV debug environment:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://10.229.222.1:11312
export ROS_IP=10.229.222.1
export GAZEBO_MASTER_URI=http://127.0.0.1:11346
```

Base debug environment:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://10.229.221.1:11311
export ROS_IP=10.229.221.1
```

Common GUI tools:

```bash
rviz -d /home/nlg/catkin1_ws/src/localizer_lamp/lamp/rviz/lamp_base.rviz
rqt_graph
rosrun rqt_tf_tree rqt_tf_tree
rqt_console
```

Gazebo clients:

```bash
# UAV Gazebo
export GAZEBO_MASTER_URI=http://127.0.0.1:11345
gzclient
```

```bash
# UGV Gazebo
export GAZEBO_MASTER_URI=http://127.0.0.1:11346
gzclient
```

UAV topic checks:

```bash
rostopic hz /keyframe_vae /uav1/lamp/keyed_scans /uav1_fusion_base/lamp/octree_map
rostopic echo -n1 /mavros/local_position/odom
rostopic echo -n1 /lio/odom
rostopic echo -n1 /uav1_fusion_base/lamp/octree_map/header
rosrun tf tf_monitor world uav1/lidar
```

UGV topic checks:

```bash
rostopic hz /keyframe_vae /ugv1/lamp/keyed_scans /ugv1_fusion_base/lamp/octree_map
rostopic echo -n1 /lio/odom
rostopic echo -n1 /ugv1_fusion_base/lamp/octree_map/header
rosrun tf tf_monitor world ugv1/lidar
```

Base topic checks:

```bash
rostopic hz /none_iris/keyframe_vae /jackal/keyframe_vae /base1/lamp/pose_graph /base1/lamp/octree_map
rostopic echo -n1 /base1/lamp/octree_map/header
rostopic echo -n1 /base1/pose_graph_visualizer/odometry_edges/header
```

## Runtime Tuning

Vehicle spawn positions and map offsets are centralized in `run/lib/config.sh`.
Override them from the shell when needed:

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

Use a different Gazebo world:

```bash
cd /home/nlg/all_ws
SIM_WORLD_FILE=$HOME/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic/worlds/empty.world \
./run/run_mrm.sh --distributed --no-attach
```

## UGV CMU Planner

`./run/run_mrm.sh --only ugv` starts the CMU local planner by default.

Planner inputs:

```text
state estimation: /lio/odom
registered scan:  /lio/cloud_world
```

Planner outputs:

```text
/cmd_vel
/cmd_vel2
/path
/terrain_map
/way_point
```

Jackal `twist_mux` forwards `/cmd_vel` to:

```text
/jackal_velocity_controller/cmd_vel
```

Disable the planner for mapping-only runs:

```bash
cd /home/nlg/all_ws
UGV_ENABLE_CMU_PLANNER=false ./run/run_mrm.sh --only ugv --no-attach
```

Tune test speed:

```bash
cd /home/nlg/all_ws
UGV_CMU_AUTONOMY_SPEED=0.2 UGV_CMU_WAYPOINT_SPEED=0.2 ./run/run_mrm.sh --only ugv --no-attach
```

Check planner output:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://10.229.222.1:11312
export ROS_IP=10.229.222.1
rostopic hz /path /terrain_map /way_point /cmd_vel /jackal_velocity_controller/cmd_vel
```

Planner RViz:

```bash
rviz -d /home/nlg/all_ws/src/cmu-planner/vehicle_simulator/rviz/vehicle_simulator.rviz
```

## UAV PX4 Sequence Controller

`./run/run_mrm.sh --only uav` starts the PX4 sequence-controller wrapper by
default. The run-mrm default mission is:

```text
/home/nlg/all_ws/src/emb/px4_controllers/sequence_controller/cfg/run_mrm_uav_takeoff_land.yaml
```

It starts `geometric_controller`, waits for MAVROS local pose, then runs the
sequence parser. The default sequence takes off to 2 m and lands.

Disable it for mapping-only UAV runs:

```bash
cd /home/nlg/all_ws
UAV_ENABLE_SEQUENCE_CONTROLLER=false ./run/run_mrm.sh --only uav --no-attach
```

Run a custom sequence:

```bash
cd /home/nlg/all_ws
UAV_SEQUENCE_YAML=/home/nlg/all_ws/src/emb/px4_controllers/sequence_controller/cfg/seq.yaml \
UAV_SEQUENCE_RUN_GPS_SERVER=true \
UAV_SEQUENCE_RUN_EXTERNAL_SCRIPTS=true \
./run/run_mrm.sh --only uav --no-attach
```

Check the controller:

```bash
source /home/nlg/all_ws/devel/setup.bash
export ROS_MASTER_URI=http://10.249.171.1:11313
export ROS_IP=10.249.171.1
rostopic echo -n1 /sequence/status
rosservice call /controller/get_mode "{}"
rostopic hz /mavros/local_position/pose /debug/path
```

## VAE Model Selection

Both simulated robots currently use Velodyne VLP-16 style input through
Super-LIO, so both default to the pcl-vae `ground` config:

```text
UAV_VAE_ROBOT_TYPE=ground
UGV_VAE_ROBOT_TYPE=ground
```

Default ground model:

```text
/home/nlg/all_ws/src/pcl-vae/pcl_vae/weights/ground_model_LD_32_epoch_20_batch_16_range_20_voxel_20.pth
```

The encoder and every decoder must use the same VAE robot type for the same
robot. If the UAV later changes back to an Ouster 64 aerial setup:

```bash
cd /home/nlg/all_ws
UAV_VAE_ROBOT_TYPE=aerial ./run/run_mrm.sh --distributed --no-attach
```

## WiFi Payload Measurement

These commands are manual measurement tools. They do not change runtime state.

Find the real WiFi interface name:

```bash
ip -brief link
iw dev
ip route get 8.8.8.8
```

Replace `wlp0s20f3` with your interface.

Measure total bytes crossing the interface:

```bash
watch -n 1 "ip -s link show wlp0s20f3"
nload wlp0s20f3
```

Measure per-connection or per-process traffic:

```bash
sudo iftop -i wlp0s20f3
sudo nethogs wlp0s20f3
ss -tupn | grep -E '1234|1235|2234|2235|6234|6235'
```

Capture MOCHA/ZeroMQ traffic on WiFi:

```bash
sudo tcpdump -i wlp0s20f3 -nn -tttt \
  'tcp port 1234 or tcp port 1235 or tcp port 2234 or tcp port 2235 or tcp port 6234 or tcp port 6235'
```

Save packets for Wireshark:

```bash
sudo tcpdump -i wlp0s20f3 -w mocha_payload.pcap \
  'tcp port 1234 or tcp port 1235 or tcp port 2234 or tcp port 2235 or tcp port 6234 or tcp port 6235'
```

For single-laptop simulation, capture loopback traffic:

```bash
sudo tcpdump -i lo -nn -tttt \
  'tcp port 1234 or tcp port 1235 or tcp port 2234 or tcp port 2235 or tcp port 6234 or tcp port 6235'
```

Measure ROS topic payload before MOCHA transport:

```bash
rostopic bw /keyframe_vae
rostopic bw /none_iris/keyframe_vae
rostopic bw /jackal/keyframe_vae
rostopic bw /uav1/lamp/keyed_scans
rostopic bw /ugv1/lamp/keyed_scans
rostopic bw /base1/lamp/octree_map
```

Check MOCHA synchronized payload statistics:

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

Useful `/ddb/client_stats/<robot>` fields:

| Field | Meaning |
| --- | --- |
| `answ_len` | Reply payload size in bytes |
| `bw` | Computed reply bandwidth |
| `rtt` | Request/reply round-trip time |
| `msg` | MOCHA protocol message type |

Interpretation:

| Tool | What it measures |
| --- | --- |
| `rostopic bw` | ROS publication payload on one ROS master |
| `/ddb/client_stats/*` | MOCHA sync reply statistics |
| `tcpdump`, `iftop`, `nethogs` | Actual traffic on the network interface |

## Range Image Debug

Start the visualizer:

```bash
roslaunch super_lio_lamp_adapter range_image_visualizer.launch
```

View the generated image topics:

```bash
rqt_image_view /range_image_viz/input_mono8
rqt_image_view /range_image_viz/output_mono8
rqt_image_view /range_image_viz/difference_mono8
```

To inspect another topic, pass launch arguments:

```bash
roslaunch super_lio_lamp_adapter range_image_visualizer.launch \
  input_topic:=/jackal/point_to_range_image/range_image \
  output_topic:=/jackal/vae_encoder/output/reconstruction
```

## Troubleshooting Notes

UAV mapping uses Super-LIO pose and cloud together:

```text
odom:  /lio/odom
cloud: /lio/cloud_body
```

Keeping both inputs from Super-LIO avoids mixing `/mavros/local_position/odom`
with `/lio/cloud_body`. On startup, PX4/MAVROS can take time to initialize IMU
attitude and local odometry. During that period Super-LIO and `/keyframe_vae`
may be quiet even if `/velodyne_points` is already publishing.

The LAMP adapter filters non-finite XYZ points before publishing keyed scans.
This prevents LAMP from crashing if Super-LIO briefly emits `nan` or `inf`
points during startup.

To temporarily test the PX4/MAVROS odometry fallback:

```bash
cd /home/nlg/all_ws
UAV_ODOM_TOPIC=/mavros/local_position/odom ./run/run_mrm.sh --distributed --no-attach
```

If VAE fails with CUDA out of memory, stop stale runs and check GPU processes:

```bash
cd /home/nlg/all_ws
./run/run_mrm.sh --kill
nvidia-smi
```

If distributed maps look different, first confirm both masters have both keyed
scan topics. Different maps usually mean one side is still missing remote
keyframes, has a VAE type mismatch, or is viewing a different ROS master.
