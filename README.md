# run_mrm Runtime and Manual Debug Commands

`run_mrm.sh` starts runtime tasks only. It does not automatically start RViz,
rqt tools, `watch`, `roswtf`, or log-following panes. Use the commands below
from separate terminals when you need GUI or ROS inspection tools.

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
