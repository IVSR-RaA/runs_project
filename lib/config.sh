#!/usr/bin/env bash
# lib/config.sh
# Runtime configuration and environment variables.

set -u

SESSION="${SESSION:-mrm-debug}"
SESSION_STATE_DIR="${SESSION_STATE_DIR:-/tmp/run_mrm_${SESSION}}"
SESSION_STATE_FILE="${SESSION_STATE_FILE:-/tmp/run_mrm_${SESSION}.state_dir}"
WS="${WS:-/home/nlg/all_ws}"
RUN_ONLY="${RUN_ONLY:-all}"
ATTACH_ON_START="${ATTACH_ON_START:-true}"
LAMP_MODE="${LAMP_MODE:-base}"

# Split ROS master data into IP/URI variables so loopback setup can validate IPs.
UAV_IP="${UAV_IP:-10.249.171.1}"
UGV_IP="${UGV_IP:-10.229.222.1}"
BASE_IP="${BASE_IP:-10.229.221.1}"
UAV_MASTER_URI="${UAV_MASTER_URI:-http://$UAV_IP:11313}"
UGV_MASTER_URI="${UGV_MASTER_URI:-http://$UGV_IP:11312}"
BASE_MASTER_URI="${BASE_MASTER_URI:-http://$BASE_IP:11311}"

# Single-machine simulation uses virtual loopback IP aliases. Real multi-host
# runs should set this to false and use the IPs already assigned to WiFi/Ethernet.
MANAGE_LOOPBACK_ALIASES="${MANAGE_LOOPBACK_ALIASES:-true}"

# Keep UAV and UGV on separate Gazebo masters. With the current stacks, sharing
# Gazebo also forces shared /gazebo services and risks global topic collisions.
UAV_GAZEBO_MASTER_URI="${UAV_GAZEBO_MASTER_URI:-http://127.0.0.1:11345}"
UGV_GAZEBO_MASTER_URI="${UGV_GAZEBO_MASTER_URI:-http://127.0.0.1:11346}"
SIM_WORLD_FILE="${SIM_WORLD_FILE:-$HOME/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic/worlds/empty.world}"

MOCHA_ROBOT_CONFIG="${MOCHA_ROBOT_CONFIG:-}"
MOCHA_ROBOT_CONFIG_ARG=""
BASE_LAMP_ROBOT_NAMES_CONFIG="${BASE_LAMP_ROBOT_NAMES_CONFIG:-}"
BASE_RSSI_PARAMETERS_CONFIG="${BASE_RSSI_PARAMETERS_CONFIG:-}"
RUN_GNN_BATCHER="${RUN_GNN_BATCHER:-false}"

# Initial vehicle pose. The map offsets default to spawn x/y so Gazebo and
# LAMP/RViz stay aligned from one place.
UAV_SPAWN_X="${UAV_SPAWN_X:-0}"
UAV_SPAWN_Y="${UAV_SPAWN_Y:-0}"
UAV_SPAWN_Z="${UAV_SPAWN_Z:-0.5}"
UAV_SPAWN_ROLL="${UAV_SPAWN_ROLL:-0}"
UAV_SPAWN_PITCH="${UAV_SPAWN_PITCH:-0}"
UAV_SPAWN_YAW="${UAV_SPAWN_YAW:-0}"
UGV_SPAWN_X="${UGV_SPAWN_X:-1}"
UGV_SPAWN_Y="${UGV_SPAWN_Y:-0}"
UGV_SPAWN_Z="${UGV_SPAWN_Z:-0.5}"
UGV_SPAWN_YAW="${UGV_SPAWN_YAW:-0}"
UGV_SPAWN_DELAY="${UGV_SPAWN_DELAY:-8}"
UAV_MAP_X="${UAV_MAP_X:-$UAV_SPAWN_X}"
UAV_MAP_Y="${UAV_MAP_Y:-$UAV_SPAWN_Y}"
UAV_MAP_Z="${UAV_MAP_Z:-0}"
UGV_MAP_X="${UGV_MAP_X:-$UGV_SPAWN_X}"
UGV_MAP_Y="${UGV_MAP_Y:-$UGV_SPAWN_Y}"
UGV_MAP_Z="${UGV_MAP_Z:-0}"

# These are shell snippets executed inside tmux panes.
UAV_ROS_ENV="export ROS_MASTER_URI=$UAV_MASTER_URI; export ROS_IP=$UAV_IP; export GAZEBO_MASTER_URI=$UAV_GAZEBO_MASTER_URI"
UGV_ROS_ENV="export ROS_MASTER_URI=$UGV_MASTER_URI; export ROS_IP=$UGV_IP; export GAZEBO_MASTER_URI=$UGV_GAZEBO_MASTER_URI"
BASE_ROS_ENV="export ROS_MASTER_URI=$BASE_MASTER_URI; export ROS_IP=$BASE_IP"

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

# Sensor input topics.
UAV_LIDAR_TOPIC="${UAV_LIDAR_TOPIC:-/velodyne_points}"
UGV_LIDAR_TOPIC="${UGV_LIDAR_TOPIC:-/mid/points}"
UAV_IMU_TOPIC="${UAV_IMU_TOPIC:-/mavros/imu/data}"
UGV_IMU_TOPIC="${UGV_IMU_TOPIC:-/imu/data}"
UAV_VAE_POINT_TOPIC="${UAV_VAE_POINT_TOPIC:-$UAV_LIDAR_TOPIC}"
UGV_VAE_POINT_TOPIC="${UGV_VAE_POINT_TOPIC:-$UGV_LIDAR_TOPIC}"

# VAE model/config type. Both simulated robots currently use Velodyne VLP-16
# input through Super-LIO, so both default to the ground/VLP-16 VAE config.
UAV_VAE_ROBOT_TYPE="${UAV_VAE_ROBOT_TYPE:-ground}"
UGV_VAE_ROBOT_TYPE="${UGV_VAE_ROBOT_TYPE:-ground}"

# Odometry consumed by TF, VAE keyframes, and LAMP input. Keep this paired with
# /lio/cloud_body so LAMP receives pose and scan data from the same SLAM source.
UAV_ODOM_TOPIC="${UAV_ODOM_TOPIC:-/lio/odom}"
UGV_ODOM_TOPIC="${UGV_ODOM_TOPIC:-/lio/odom}"
UAV_CLOUD_BODY_TOPIC="${UAV_CLOUD_BODY_TOPIC:-/lio/cloud_body}"
UGV_CLOUD_BODY_TOPIC="${UGV_CLOUD_BODY_TOPIC:-/lio/cloud_body}"

# CMU local planner integration for the UGV. It consumes Super-LIO odometry and
# registered world cloud, then publishes Jackal-compatible /cmd_vel.
UGV_ENABLE_CMU_PLANNER="${UGV_ENABLE_CMU_PLANNER:-true}"
UGV_CMU_STATE_TOPIC="${UGV_CMU_STATE_TOPIC:-$UGV_ODOM_TOPIC}"
UGV_CMU_SCAN_TOPIC="${UGV_CMU_SCAN_TOPIC:-/lio/cloud_world}"
UGV_CMU_CMD_VEL_TOPIC="${UGV_CMU_CMD_VEL_TOPIC:-/cmd_vel}"
UGV_CMU_CMD_VEL_STAMPED_TOPIC="${UGV_CMU_CMD_VEL_STAMPED_TOPIC:-/cmd_vel2}"
UGV_CMU_RUN_WAYPOINTS="${UGV_CMU_RUN_WAYPOINTS:-true}"
UGV_CMU_MAX_SPEED="${UGV_CMU_MAX_SPEED:-0.6}"
UGV_CMU_AUTONOMY_SPEED="${UGV_CMU_AUTONOMY_SPEED:-0.4}"
UGV_CMU_WAYPOINT_SPEED="${UGV_CMU_WAYPOINT_SPEED:-0.4}"
UGV_CMU_WAYPOINT_FILE="${UGV_CMU_WAYPOINT_FILE:-}"
UGV_CMU_BOUNDARY_FILE="${UGV_CMU_BOUNDARY_FILE:-}"

# UAV PX4 sequence-controller integration. The default mission is intentionally
# small for run_mrm: take off to 2 m, then land. Use UAV_SEQUENCE_YAML to run a
# custom mission such as sequence_controller/cfg/seq.yaml.
UAV_ENABLE_SEQUENCE_CONTROLLER="${UAV_ENABLE_SEQUENCE_CONTROLLER:-true}"
UAV_SEQUENCE_YAML="${UAV_SEQUENCE_YAML:-$WS/src/emb/px4_controllers/sequence_controller/cfg/run_mrm_uav_takeoff_land.yaml}"
UAV_SEQUENCE_RUN_PARSER="${UAV_SEQUENCE_RUN_PARSER:-true}"
UAV_SEQUENCE_RUN_GEOMETRIC_CONTROLLER="${UAV_SEQUENCE_RUN_GEOMETRIC_CONTROLLER:-true}"
UAV_SEQUENCE_RUN_GPS_SERVER="${UAV_SEQUENCE_RUN_GPS_SERVER:-false}"
UAV_SEQUENCE_RUN_EXTERNAL_SCRIPTS="${UAV_SEQUENCE_RUN_EXTERNAL_SCRIPTS:-false}"
UAV_SEQUENCE_MAV_NAME="${UAV_SEQUENCE_MAV_NAME:-tarot}"

# Frames used by reconstruction and RViz debug commands.
WORLD_FRAME="${WORLD_FRAME:-world}"
UAV_LIDAR_FRAME="${UAV_LIDAR_FRAME:-$UAV_LAMP_ROBOT/lidar}"
UGV_LIDAR_FRAME="${UGV_LIDAR_FRAME:-$UGV_LAMP_ROBOT/lidar}"

COMMON_SETUP='source ~/.bashrc'
PREFLIGHT_SETUP="source /opt/ros/noetic/setup.bash; source $WS/devel/setup.bash; source /usr/share/gazebo/setup.bash; source $HOME/PX4-Autopilot/Tools/simulation/gazebo-classic/setup_gazebo.bash $HOME/PX4-Autopilot $HOME/PX4-Autopilot/build/px4_sitl_default; export ROS_PACKAGE_PATH=$HOME/PX4-Autopilot:\$ROS_PACKAGE_PATH; export ROS_PACKAGE_PATH=$HOME/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic:\$ROS_PACKAGE_PATH"
VAE_SETUP="$COMMON_SETUP; [ -f /home/nlg/pcl-vae/env/bin/activate ] && source /home/nlg/pcl-vae/env/bin/activate"

WAIT_FOR_MASTER='until rostopic list >/dev/null 2>&1; do echo "[wait] ROS master at ${ROS_MASTER_URI}"; sleep 1; done'
WAIT_FOR_UAV_SENSORS="until rostopic list 2>/dev/null | grep -qx \"$UAV_LIDAR_TOPIC\" && rostopic list 2>/dev/null | grep -qx \"$UAV_IMU_TOPIC\"; do echo \"[wait] UAV sensor topics\"; sleep 1; done"
WAIT_FOR_UAV_LIO_OUTPUTS="until rostopic list 2>/dev/null | grep -qx \"$UAV_CLOUD_BODY_TOPIC\" && timeout 2s rostopic echo -n 1 \"$UAV_ODOM_TOPIC\" >/dev/null 2>&1; do echo \"[wait] UAV Super-LIO cloud and odom output\"; sleep 1; done"
WAIT_FOR_GAZEBO='until rosservice list 2>/dev/null | grep -qx "/gazebo/spawn_urdf_model"; do echo "[wait] Gazebo spawn service"; sleep 1; done'
WAIT_FOR_UGV_SENSORS="until rostopic list 2>/dev/null | grep -qx \"$UGV_LIDAR_TOPIC\" && rostopic list 2>/dev/null | grep -qx \"$UGV_IMU_TOPIC\"; do echo \"[wait] UGV sensor topics\"; sleep 1; done"
WAIT_FOR_UGV_LIO_OUTPUTS="until rostopic list 2>/dev/null | grep -qx \"$UGV_CLOUD_BODY_TOPIC\" && timeout 2s rostopic echo -n 1 \"$UGV_ODOM_TOPIC\" >/dev/null 2>&1; do echo \"[wait] UGV Super-LIO cloud and odom output\"; sleep 1; done"
WAIT_FOR_UGV_CMU_INPUTS="until rostopic list 2>/dev/null | grep -qx \"$UGV_CMU_SCAN_TOPIC\" && timeout 2s rostopic echo -n 1 \"$UGV_CMU_STATE_TOPIC\" >/dev/null 2>&1; do echo \"[wait] UGV CMU planner scan and odom input\"; sleep 1; done"

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
