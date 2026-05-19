#!/usr/bin/env bash
# lib/config.sh
# Configuration and environment variables

set -u  # Treat use of an unset variable as an error.

SESSION="${SESSION:-mrm-debug}"
SESSION_STATE_FILE="${SESSION_STATE_FILE:-/tmp/run_debug_multi_robot_mapping_${SESSION}.logdir}"
WS="${WS:-/home/nlg/all_ws}"
LOG_ROOT="${LOG_ROOT:-$WS/debug_logs}"
RUN_ONLY="${RUN_ONLY:-all}"
ATTACH_ON_START="${ATTACH_ON_START:-true}"
LAMP_MODE="${LAMP_MODE:-base}"

STAMP="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="${LOG_DIR:-$LOG_ROOT/$STAMP}"

# Split ROS master data into IP/URI variables so loopback setup can validate IPs.
UAV_IP="${UAV_IP:-10.249.171.1}"
UGV_IP="${UGV_IP:-10.229.222.1}"
BASE_IP="${BASE_IP:-10.229.221.1}"
UAV_MASTER_URI="${UAV_MASTER_URI:-http://$UAV_IP:11313}"
UGV_MASTER_URI="${UGV_MASTER_URI:-http://$UGV_IP:11312}"
BASE_MASTER_URI="${BASE_MASTER_URI:-http://$BASE_IP:11311}"
UAV_GAZEBO_MASTER_URI="${UAV_GAZEBO_MASTER_URI:-http://127.0.0.1:11345}"
UGV_GAZEBO_MASTER_URI="${UGV_GAZEBO_MASTER_URI:-http://127.0.0.1:11346}"
VISUAL_GAZEBO_MASTER_URI="${VISUAL_GAZEBO_MASTER_URI:-$UAV_GAZEBO_MASTER_URI}"
SIM_WORLD_FILE="${SIM_WORLD_FILE:-$HOME/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic/worlds/empty.world}"
MOCHA_ROBOT_CONFIG="${MOCHA_ROBOT_CONFIG:-}"
MOCHA_ROBOT_CONFIG_ARG=""
BASE_LAMP_ROBOT_NAMES_CONFIG="${BASE_LAMP_ROBOT_NAMES_CONFIG:-}"
BASE_RSSI_PARAMETERS_CONFIG="${BASE_RSSI_PARAMETERS_CONFIG:-}"
RUN_GNN_BATCHER="${RUN_GNN_BATCHER:-false}"

# These are shell snippets executed inside tmux panes.
UAV_ROS_ENV="export ROS_MASTER_URI=$UAV_MASTER_URI; export ROS_IP=$UAV_IP; export GAZEBO_MASTER_URI=$UAV_GAZEBO_MASTER_URI"
UGV_ROS_ENV="export ROS_MASTER_URI=$UGV_MASTER_URI; export ROS_IP=$UGV_IP; export GAZEBO_MASTER_URI=$UGV_GAZEBO_MASTER_URI"
BASE_ROS_ENV="export ROS_MASTER_URI=$BASE_MASTER_URI; export ROS_IP=$BASE_IP"
VISUAL_GAZEBO_ENV="export GAZEBO_MASTER_URI=$VISUAL_GAZEBO_MASTER_URI"

# Keep MOCHA robot names separate from LAMP robot names.
UAV_MOCHA_ROBOT="${UAV_MOCHA_ROBOT:-none_iris}"
UGV_MOCHA_ROBOT="${UGV_MOCHA_ROBOT:-jackal}"
UAV_LAMP_ROBOT="${UAV_LAMP_ROBOT:-uav1}"
UGV_LAMP_ROBOT="${UGV_LAMP_ROBOT:-ugv1}"
UAV_FUSION_NAMESPACE="${UAV_FUSION_NAMESPACE:-${UAV_LAMP_ROBOT}_fusion_base}"
UGV_FUSION_NAMESPACE="${UGV_FUSION_NAMESPACE:-${UGV_LAMP_ROBOT}_fusion_base}"
UAV_LAMP_PREFIX="${UAV_LAMP_PREFIX:-a}"
UGV_LAMP_PREFIX="${UGV_LAMP_PREFIX:-b}"
RSSI_ROBOTS_WAS_SET="${RSSI_ROBOTS+x}"
RSSI_ROBOTS="${RSSI_ROBOTS:-$UAV_MOCHA_ROBOT $UGV_MOCHA_ROBOT basestation}"
DISTRIBUTED_VISUAL_ROBOT="${DISTRIBUTED_VISUAL_ROBOT:-uav}"

# Default lidar topics
UAV_LIDAR_TOPIC="${UAV_LIDAR_TOPIC:-/velodyne_points}"
UGV_LIDAR_TOPIC="${UGV_LIDAR_TOPIC:-/mid/points}"
UAV_IMU_TOPIC="${UAV_IMU_TOPIC:-/mavros/imu/data_raw}"
UAV_VAE_POINT_TOPIC="${UAV_VAE_POINT_TOPIC:-$UAV_LIDAR_TOPIC}"
UGV_VAE_POINT_TOPIC="${UGV_VAE_POINT_TOPIC:-$UGV_LIDAR_TOPIC}"

# Super-LIO outputs
UAV_ODOM_TOPIC="${UAV_ODOM_TOPIC:-/lio/odom}"
UGV_ODOM_TOPIC="${UGV_ODOM_TOPIC:-/lio/odom}"
UAV_CLOUD_BODY_TOPIC="${UAV_CLOUD_BODY_TOPIC:-/lio/cloud_body}"
UGV_CLOUD_BODY_TOPIC="${UGV_CLOUD_BODY_TOPIC:-/lio/cloud_body}"

# Frames monitored and used by reconstruction.
WORLD_FRAME="${WORLD_FRAME:-world}"
UAV_LIDAR_FRAME="${UAV_LIDAR_FRAME:-$UAV_LAMP_ROBOT/lidar}"
UGV_LIDAR_FRAME="${UGV_LIDAR_FRAME:-$UGV_LAMP_ROBOT/lidar}"

# Environment setups
COMMON_SETUP='source ~/.bashrc'
PREFLIGHT_SETUP="source /opt/ros/noetic/setup.bash; source $WS/devel/setup.bash; source /usr/share/gazebo/setup.bash; source $HOME/PX4-Autopilot/Tools/simulation/gazebo-classic/setup_gazebo.bash $HOME/PX4-Autopilot $HOME/PX4-Autopilot/build/px4_sitl_default; export ROS_PACKAGE_PATH=$HOME/PX4-Autopilot:\$ROS_PACKAGE_PATH; export ROS_PACKAGE_PATH=$HOME/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic:\$ROS_PACKAGE_PATH"
VAE_SETUP="$COMMON_SETUP; [ -f /home/nlg/pcl-vae/env/bin/activate ] && source /home/nlg/pcl-vae/env/bin/activate"

# Wait loops
WAIT_FOR_MASTER='until rostopic list >/dev/null 2>&1; do echo "[debug] waiting for ROS master at ${ROS_MASTER_URI}"; sleep 1; done'
WAIT_FOR_UAV_SENSORS="until rostopic list 2>/dev/null | grep -qx \"$UAV_LIDAR_TOPIC\" && rostopic list 2>/dev/null | grep -qx \"$UAV_IMU_TOPIC\"; do echo \"[debug] waiting for UAV sensor topics\"; sleep 1; done"
WAIT_FOR_UAV_LIO_OUTPUTS='until rostopic list 2>/dev/null | grep -qx "/lio/odom" && rostopic list 2>/dev/null | grep -qx "/lio/cloud_body"; do echo "[debug] waiting for UAV Super-LIO outputs"; sleep 1; done'
WAIT_FOR_GAZEBO='until rosservice list 2>/dev/null | grep -qx "/gazebo/spawn_urdf_model"; do echo "[debug] waiting for Gazebo spawn service"; sleep 1; done'
WAIT_FOR_UGV_SENSORS='until rostopic list 2>/dev/null | grep -qx "/mid/points" && rostopic list 2>/dev/null | grep -qx "/imu/data"; do echo "[debug] waiting for UGV sensor topics"; sleep 1; done'
WAIT_FOR_UGV_LIO_OUTPUTS='until rostopic list 2>/dev/null | grep -qx "/lio/odom" && rostopic list 2>/dev/null | grep -qx "/lio/cloud_body"; do echo "[debug] waiting for UGV Super-LIO outputs"; sleep 1; done'

# PX4 model path
resolve_px4_uav_sdf() {
  local candidate
  local candidates=(
    "${PX4_UAV_SDF:-}"
    "$HOME/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic/models/tarot/tarot.sdf"
    "$HOME/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic/models/iris_rplidar/iris_rplidar.sdf"
  )
  for candidate in "${candidates[@]}"; do
    if [[ -n "$candidate" && -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

PX4_UAV_SDF="$(resolve_px4_uav_sdf || true)"
RVIZ_CONFIG="${RVIZ_CONFIG:-/home/nlg/catkin1_ws/src/localizer_lamp/lamp/rviz/lamp_base.rviz}"

mkdir -p "$LOG_DIR"
touch "$LOG_DIR/session.log"


distributed_base1_compat_relays() {
  local fusion_namespace="$1"
  local relay_prefix="$2"

  printf '%s' "rosrun topic_tools relay /$fusion_namespace/lamp/keyed_scans /base1/lamp/keyed_scans __name:=${relay_prefix}_keyed_scans_to_base1 >/dev/null 2>&1 & "
  printf '%s' "rosrun topic_tools relay /$fusion_namespace/lamp/pose_graph /base1/lamp/pose_graph __name:=${relay_prefix}_pose_graph_to_base1 >/dev/null 2>&1 & "
  printf '%s' "rosrun topic_tools relay /$fusion_namespace/lamp/octree_map /base1/lamp/octree_map __name:=${relay_prefix}_octree_map_to_base1 >/dev/null 2>&1 & "
  printf '%s' "rosrun topic_tools relay /$fusion_namespace/lamp_pgo/optimized_values /base1/lamp_pgo/optimized_values __name:=${relay_prefix}_optimized_values_to_base1 >/dev/null 2>&1 & "
}
