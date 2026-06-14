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

# Delay an entire runtime group by delaying its ROS master. All other panes in
# that group already wait for the master, so they start together afterward.
UAV_START_DELAY="${UAV_START_DELAY:-0}"
UGV_START_DELAY="${UGV_START_DELAY:-0}"
HUSKY_START_DELAY="${HUSKY_START_DELAY:-0}"
BASE_START_DELAY="${BASE_START_DELAY:-0}"

# Split ROS master data into IP/URI variables so loopback setup can validate IPs.
UAV_IP="${UAV_IP:-10.249.171.1}"
UGV_IP="${UGV_IP:-10.229.222.1}"
HUSKY_IP="${HUSKY_IP:-10.229.223.1}"
BASE_IP="${BASE_IP:-10.229.221.1}"
UAV_MASTER_URI="${UAV_MASTER_URI:-http://$UAV_IP:11313}"
UGV_MASTER_URI="${UGV_MASTER_URI:-http://$UGV_IP:11312}"
HUSKY_MASTER_URI="${HUSKY_MASTER_URI:-http://$HUSKY_IP:11314}"
BASE_MASTER_URI="${BASE_MASTER_URI:-http://$BASE_IP:11311}"

# Single-machine simulation uses virtual loopback IP aliases. Real multi-host
# runs should set this to false and use the IPs already assigned to WiFi/Ethernet.
MANAGE_LOOPBACK_ALIASES="${MANAGE_LOOPBACK_ALIASES:-true}"

# Keep UAV and UGV on separate Gazebo masters. With the current stacks, sharing
# Gazebo also forces shared /gazebo services and risks global topic collisions.
UAV_GAZEBO_MASTER_URI="${UAV_GAZEBO_MASTER_URI:-http://127.0.0.1:11345}"
UGV_GAZEBO_MASTER_URI="${UGV_GAZEBO_MASTER_URI:-http://127.0.0.1:11346}"
HUSKY_GAZEBO_MASTER_URI="${HUSKY_GAZEBO_MASTER_URI:-http://127.0.0.1:11347}"
SIM_WORLD_FILE="${SIM_WORLD_FILE:-$HOME/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic/worlds/empty.world}"

MOCHA_ROBOT_CONFIG="${MOCHA_ROBOT_CONFIG:-}"
MOCHA_ROBOT_CONFIG_ARG=""
BASE_LAMP_ROBOT_NAMES_CONFIG="${BASE_LAMP_ROBOT_NAMES_CONFIG:-}"
BASE_RSSI_PARAMETERS_CONFIG="${BASE_RSSI_PARAMETERS_CONFIG:-}"
RUN_GNN_BATCHER="${RUN_GNN_BATCHER:-false}"
USE_SOLID_LOOP_CONDITION="${USE_SOLID_LOOP_CONDITION:-false}"
SOLID_SIMILARITY_THRESHOLD="${SOLID_SIMILARITY_THRESHOLD:-0.80}"
LAMP_SOLID_ARGS="use_solid_loop_condition:=$USE_SOLID_LOOP_CONDITION solid_similarity_threshold:=$SOLID_SIMILARITY_THRESHOLD"

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
HUSKY_SPAWN_X="${HUSKY_SPAWN_X:-2}"
HUSKY_SPAWN_Y="${HUSKY_SPAWN_Y:-0}"
HUSKY_SPAWN_Z="${HUSKY_SPAWN_Z:-0.5}"
HUSKY_SPAWN_YAW="${HUSKY_SPAWN_YAW:-0}"
HUSKY_SPAWN_DELAY="${HUSKY_SPAWN_DELAY:-8}"
UAV_MAP_X="${UAV_MAP_X:-$UAV_SPAWN_X}"
UAV_MAP_Y="${UAV_MAP_Y:-$UAV_SPAWN_Y}"
UAV_MAP_Z="${UAV_MAP_Z:-0}"
UGV_MAP_X="${UGV_MAP_X:-$UGV_SPAWN_X}"
UGV_MAP_Y="${UGV_MAP_Y:-$UGV_SPAWN_Y}"
UGV_MAP_Z="${UGV_MAP_Z:-0}"
HUSKY_MAP_X="${HUSKY_MAP_X:-$HUSKY_SPAWN_X}"
HUSKY_MAP_Y="${HUSKY_MAP_Y:-$HUSKY_SPAWN_Y}"
HUSKY_MAP_Z="${HUSKY_MAP_Z:-0}"

# These are shell snippets executed inside tmux panes.
UAV_ROS_ENV="export ROS_MASTER_URI=$UAV_MASTER_URI; export ROS_IP=$UAV_IP; export GAZEBO_MASTER_URI=$UAV_GAZEBO_MASTER_URI"
UGV_ROS_ENV="export ROS_MASTER_URI=$UGV_MASTER_URI; export ROS_IP=$UGV_IP; export GAZEBO_MASTER_URI=$UGV_GAZEBO_MASTER_URI"
HUSKY_ROS_ENV="export ROS_MASTER_URI=$HUSKY_MASTER_URI; export ROS_IP=$HUSKY_IP; export GAZEBO_MASTER_URI=$HUSKY_GAZEBO_MASTER_URI"
BASE_ROS_ENV="export ROS_MASTER_URI=$BASE_MASTER_URI; export ROS_IP=$BASE_IP"

# Public transport names stay close to the simulator/model names used by Mocha.
# LAMP map namespaces use numeric suffixes for stable map/TF/debug separation.
UAV_MOCHA_ROBOT="${UAV_MOCHA_ROBOT:-none_iris}"
UGV_MOCHA_ROBOT="${UGV_MOCHA_ROBOT:-jackal}"
HUSKY_MOCHA_ROBOT="${HUSKY_MOCHA_ROBOT:-husky}"
UAV_LAMP_ROBOT="${UAV_LAMP_ROBOT:-none_iris2}"
UGV_LAMP_ROBOT="${UGV_LAMP_ROBOT:-jackal1}"
HUSKY_LAMP_ROBOT="${HUSKY_LAMP_ROBOT:-husky3}"
UAV_FUSION_NAMESPACE="${UAV_FUSION_NAMESPACE:-${UAV_LAMP_ROBOT}_fusion_base}"
UGV_FUSION_NAMESPACE="${UGV_FUSION_NAMESPACE:-${UGV_LAMP_ROBOT}_fusion_base}"
HUSKY_FUSION_NAMESPACE="${HUSKY_FUSION_NAMESPACE:-${HUSKY_LAMP_ROBOT}_fusion_base}"
UAV_LAMP_PREFIX="${UAV_LAMP_PREFIX:-b}"
UGV_LAMP_PREFIX="${UGV_LAMP_PREFIX:-a}"
HUSKY_LAMP_PREFIX="${HUSKY_LAMP_PREFIX:-c}"
RSSI_ROBOTS_WAS_SET="${RSSI_ROBOTS+x}"
RSSI_ROBOTS="${RSSI_ROBOTS:-$UAV_MOCHA_ROBOT $UGV_MOCHA_ROBOT $HUSKY_MOCHA_ROBOT basestation}"

# Optional RGB cameras for simulation/debug video. ENABLE_RGB_CAMERAS turns all
# three on; individual variables can override it per robot.
ENABLE_RGB_CAMERAS="${ENABLE_RGB_CAMERAS:-false}"
UAV_ENABLE_CAMERA="${UAV_ENABLE_CAMERA:-$ENABLE_RGB_CAMERAS}"
UGV_ENABLE_CAMERA="${UGV_ENABLE_CAMERA:-$ENABLE_RGB_CAMERAS}"
HUSKY_ENABLE_CAMERA="${HUSKY_ENABLE_CAMERA:-$ENABLE_RGB_CAMERAS}"

# Optional YOLOv8 object detection. Detection metadata is sent through MOCHA
# using /yolo/detections and /yolo/objects; annotated images stay local.
ENABLE_YOLO="${ENABLE_YOLO:-false}"
UAV_ENABLE_YOLO="${UAV_ENABLE_YOLO:-$ENABLE_YOLO}"
UGV_ENABLE_YOLO="${UGV_ENABLE_YOLO:-$ENABLE_YOLO}"
HUSKY_ENABLE_YOLO="${HUSKY_ENABLE_YOLO:-$ENABLE_YOLO}"
if [[ "$UAV_ENABLE_YOLO" == "true" ]]; then UAV_ENABLE_CAMERA="true"; fi
if [[ "$UGV_ENABLE_YOLO" == "true" ]]; then UGV_ENABLE_CAMERA="true"; fi
if [[ "$HUSKY_ENABLE_YOLO" == "true" ]]; then HUSKY_ENABLE_CAMERA="true"; fi
YOLO_SETUP="${YOLO_SETUP:-source ~/.bashrc; [ -f $WS/.venv-yolo/bin/activate ] && source $WS/.venv-yolo/bin/activate}"
YOLO_MODEL="${YOLO_MODEL:-yolov8n.pt}"
YOLO_DEVICE="${YOLO_DEVICE:-cpu}"
YOLO_CONFIDENCE="${YOLO_CONFIDENCE:-0.25}"
YOLO_MAX_RATE="${YOLO_MAX_RATE:-2.0}"
YOLO_ENABLE_TRACKING="${YOLO_ENABLE_TRACKING:-true}"
YOLO_TRACKER="${YOLO_TRACKER:-bytetrack.yaml}"
YOLO_TRAJECTORY_LENGTH="${YOLO_TRAJECTORY_LENGTH:-30}"
YOLO_FIXED_DEPTH_M="${YOLO_FIXED_DEPTH_M:-0.0}"
YOLO_PUBLISH_ANNOTATED="${YOLO_PUBLISH_ANNOTATED:-false}"
UAV_YOLO_IMAGE_TOPIC="${UAV_YOLO_IMAGE_TOPIC:-/$UAV_MOCHA_ROBOT/front_camera/image_raw}"
UGV_YOLO_IMAGE_TOPIC="${UGV_YOLO_IMAGE_TOPIC:-/$UGV_MOCHA_ROBOT/front_camera/image_raw}"
HUSKY_YOLO_IMAGE_TOPIC="${HUSKY_YOLO_IMAGE_TOPIC:-/$HUSKY_MOCHA_ROBOT/front_camera/image_raw}"

UGV_CAMERA_URDF_EXTRAS="${UGV_CAMERA_URDF_EXTRAS:-$WS/src/mrm_run_launch/urdf/jackal_rgb_camera.urdf.xacro}"
HUSKY_CAMERA_URDF_EXTRAS="${HUSKY_CAMERA_URDF_EXTRAS:-$WS/src/mrm_run_launch/urdf/husky_rgb_camera.urdf.xacro}"
UAV_CAMERA_SDF="${UAV_CAMERA_SDF:-$SESSION_STATE_DIR/uav_rgb_camera.sdf}"
UGV_CAMERA_ENV=""
HUSKY_CAMERA_ENV=""
if [[ "$UGV_ENABLE_CAMERA" == "true" ]]; then
  UGV_CAMERA_ENV="MRM_CAMERA_NAMESPACE=$UGV_MOCHA_ROBOT JACKAL_URDF_EXTRAS=$UGV_CAMERA_URDF_EXTRAS"
fi
if [[ "$HUSKY_ENABLE_CAMERA" == "true" ]]; then
  HUSKY_CAMERA_ENV="MRM_CAMERA_NAMESPACE=$HUSKY_MOCHA_ROBOT HUSKY_URDF_EXTRAS=$HUSKY_CAMERA_URDF_EXTRAS"
fi

# Sensor input topics.
UAV_LIDAR_TOPIC="${UAV_LIDAR_TOPIC:-/velodyne_points}"
UGV_LIDAR_TOPIC="${UGV_LIDAR_TOPIC:-/mid/points}"
HUSKY_LIDAR_TOPIC="${HUSKY_LIDAR_TOPIC:-/$HUSKY_MOCHA_ROBOT/points}"
UAV_IMU_TOPIC="${UAV_IMU_TOPIC:-/mavros/imu/data}"
UGV_IMU_TOPIC="${UGV_IMU_TOPIC:-/imu/data}"
HUSKY_IMU_TOPIC="${HUSKY_IMU_TOPIC:-/$HUSKY_MOCHA_ROBOT/imu/data}"
UAV_VAE_POINT_TOPIC="${UAV_VAE_POINT_TOPIC:-$UAV_LIDAR_TOPIC}"
UGV_VAE_POINT_TOPIC="${UGV_VAE_POINT_TOPIC:-$UGV_LIDAR_TOPIC}"
HUSKY_VAE_POINT_TOPIC="${HUSKY_VAE_POINT_TOPIC:-$HUSKY_LIDAR_TOPIC}"

# VAE model/config type. All simulated robots currently use Velodyne VLP-16
# input through Super-LIO, so they default to the ground/VLP-16 VAE config.
UAV_VAE_ROBOT_TYPE="${UAV_VAE_ROBOT_TYPE:-ground}"
UGV_VAE_ROBOT_TYPE="${UGV_VAE_ROBOT_TYPE:-ground}"
HUSKY_VAE_ROBOT_TYPE="${HUSKY_VAE_ROBOT_TYPE:-ground}"

# Odometry consumed by TF, VAE keyframes, and LAMP input. Keep this paired with
# /lio/cloud_body so LAMP receives pose and scan data from the same SLAM source.
UAV_ODOM_TOPIC="${UAV_ODOM_TOPIC:-/lio/odom}"
UGV_ODOM_TOPIC="${UGV_ODOM_TOPIC:-/lio/odom}"
HUSKY_ODOM_TOPIC="${HUSKY_ODOM_TOPIC:-/lio/odom}"
UAV_CLOUD_BODY_TOPIC="${UAV_CLOUD_BODY_TOPIC:-/lio/cloud_body}"
UGV_CLOUD_BODY_TOPIC="${UGV_CLOUD_BODY_TOPIC:-/lio/cloud_body}"
HUSKY_CLOUD_BODY_TOPIC="${HUSKY_CLOUD_BODY_TOPIC:-/lio/cloud_body}"

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

# Optional CMU local planner for the Husky. The output is namespaced because
# husky_control's twist_mux listens on /husky/cmd_vel inside the robot namespace.
HUSKY_ENABLE_CMU_PLANNER="${HUSKY_ENABLE_CMU_PLANNER:-false}"
HUSKY_CMU_STATE_TOPIC="${HUSKY_CMU_STATE_TOPIC:-$HUSKY_ODOM_TOPIC}"
HUSKY_CMU_SCAN_TOPIC="${HUSKY_CMU_SCAN_TOPIC:-/lio/cloud_world}"
HUSKY_CMU_CMD_VEL_TOPIC="${HUSKY_CMU_CMD_VEL_TOPIC:-/$HUSKY_MOCHA_ROBOT/cmd_vel}"
HUSKY_CMU_CMD_VEL_STAMPED_TOPIC="${HUSKY_CMU_CMD_VEL_STAMPED_TOPIC:-/cmd_vel2}"
HUSKY_CMU_RUN_WAYPOINTS="${HUSKY_CMU_RUN_WAYPOINTS:-true}"
HUSKY_CMU_MAX_SPEED="${HUSKY_CMU_MAX_SPEED:-0.5}"
HUSKY_CMU_AUTONOMY_SPEED="${HUSKY_CMU_AUTONOMY_SPEED:-0.3}"
HUSKY_CMU_WAYPOINT_SPEED="${HUSKY_CMU_WAYPOINT_SPEED:-0.3}"
HUSKY_CMU_WAYPOINT_FILE="${HUSKY_CMU_WAYPOINT_FILE:-}"
HUSKY_CMU_BOUNDARY_FILE="${HUSKY_CMU_BOUNDARY_FILE:-}"

# UAV PX4 sequence-controller integration. The default mission is intentionally
# small for run_mrm: take off to 2 m, then land. Use UAV_SEQUENCE_YAML to run a
# local mission such as sequence_controller/cfg/run_mrm_uav_local_square.yaml.
UAV_ENABLE_SEQUENCE_CONTROLLER="${UAV_ENABLE_SEQUENCE_CONTROLLER:-true}"
UAV_SEQUENCE_YAML="${UAV_SEQUENCE_YAML:-$WS/src/emb/px4_controllers/sequence_controller/cfg/run_mrm_uav_takeoff_land.yaml}"
UAV_SEQUENCE_RUN_PARSER="${UAV_SEQUENCE_RUN_PARSER:-true}"
UAV_SEQUENCE_RUN_GEOMETRIC_CONTROLLER="${UAV_SEQUENCE_RUN_GEOMETRIC_CONTROLLER:-true}"
UAV_SEQUENCE_RUN_LOCAL_SERVER="${UAV_SEQUENCE_RUN_LOCAL_SERVER:-true}"
UAV_SEQUENCE_RUN_GPS_SERVER="${UAV_SEQUENCE_RUN_GPS_SERVER:-false}"
UAV_SEQUENCE_RUN_EXTERNAL_SCRIPTS="${UAV_SEQUENCE_RUN_EXTERNAL_SCRIPTS:-false}"
UAV_SEQUENCE_USE_POSITION_SETPOINTS="${UAV_SEQUENCE_USE_POSITION_SETPOINTS:-false}"
UAV_SEQUENCE_MAV_NAME="${UAV_SEQUENCE_MAV_NAME:-tarot}"

# Optional EGO-Planner avoidance for sequence stages whose type starts with
# "a". Raw lidar is transformed into the MAVROS local map frame so cloud and
# odometry coordinates remain consistent even if Super-LIO loses convergence.
UAV_ENABLE_EGO_PLANNER="${UAV_ENABLE_EGO_PLANNER:-false}"
UAV_EGO_ODOM_TOPIC="${UAV_EGO_ODOM_TOPIC:-/mavros/local_position/odom}"
UAV_EGO_CLOUD_TOPIC="${UAV_EGO_CLOUD_TOPIC:-/ego_planner/cloud_world}"
UAV_EGO_USE_RAW_CLOUD_ADAPTER="${UAV_EGO_USE_RAW_CLOUD_ADAPTER:-true}"
UAV_EGO_RAW_CLOUD_TOPIC="${UAV_EGO_RAW_CLOUD_TOPIC:-$UAV_LIDAR_TOPIC}"
UAV_EGO_CLOUD_TARGET_FRAME="${UAV_EGO_CLOUD_TARGET_FRAME:-map}"
UAV_EGO_CLOUD_MINIMUM_RANGE="${UAV_EGO_CLOUD_MINIMUM_RANGE:-1.0}"
UAV_EGO_MAP_SIZE_X="${UAV_EGO_MAP_SIZE_X:-50.0}"
UAV_EGO_MAP_SIZE_Y="${UAV_EGO_MAP_SIZE_Y:-50.0}"
UAV_EGO_MAP_SIZE_Z="${UAV_EGO_MAP_SIZE_Z:-3.0}"
UAV_EGO_MAX_VELOCITY="${UAV_EGO_MAX_VELOCITY:-1.0}"
UAV_EGO_MAX_ACCELERATION="${UAV_EGO_MAX_ACCELERATION:-1.0}"
UAV_EGO_PLANNING_HORIZON="${UAV_EGO_PLANNING_HORIZON:-7.0}"
UAV_EGO_OBSTACLE_INFLATION="${UAV_EGO_OBSTACLE_INFLATION:-0.5}"
UAV_EGO_OBSTACLE_INFLATION_Z="${UAV_EGO_OBSTACLE_INFLATION_Z:-1.5}"
UAV_EGO_LAMBDA_FITNESS="${UAV_EGO_LAMBDA_FITNESS:-2.0}"
UAV_EGO_SPAWN_TEST_OBSTACLE="${UAV_EGO_SPAWN_TEST_OBSTACLE:-false}"
UAV_EGO_USE_POSITION_SETPOINTS="${UAV_EGO_USE_POSITION_SETPOINTS:-true}"

# Frames used by reconstruction and RViz debug commands.
WORLD_FRAME="${WORLD_FRAME:-world}"
UAV_LIDAR_FRAME="${UAV_LIDAR_FRAME:-$UAV_LAMP_ROBOT/lidar}"
UGV_LIDAR_FRAME="${UGV_LIDAR_FRAME:-$UGV_LAMP_ROBOT/lidar}"
HUSKY_LIDAR_FRAME="${HUSKY_LIDAR_FRAME:-$HUSKY_LAMP_ROBOT/lidar}"

COMMON_SETUP='source ~/.bashrc'
PREFLIGHT_SETUP="source /opt/ros/noetic/setup.bash; source $WS/devel/setup.bash; source /usr/share/gazebo/setup.bash; source $HOME/PX4-Autopilot/Tools/simulation/gazebo-classic/setup_gazebo.bash $HOME/PX4-Autopilot $HOME/PX4-Autopilot/build/px4_sitl_default; export ROS_PACKAGE_PATH=$HOME/PX4-Autopilot:\$ROS_PACKAGE_PATH; export ROS_PACKAGE_PATH=$HOME/PX4-Autopilot/Tools/simulation/gazebo-classic/sitl_gazebo-classic:\$ROS_PACKAGE_PATH"
VAE_SETUP="$COMMON_SETUP; [ -f /home/nlg/pcl-vae/env/bin/activate ] && source /home/nlg/pcl-vae/env/bin/activate"

WAIT_FOR_MASTER='until rostopic list >/dev/null 2>&1; do echo "[wait] ROS master at ${ROS_MASTER_URI}"; sleep 1; done'
LIO_OUTPUT_ECHO_TIMEOUT="${LIO_OUTPUT_ECHO_TIMEOUT:-10}"
WAIT_FOR_UAV_SENSORS="until rostopic list 2>/dev/null | grep -qx \"$UAV_LIDAR_TOPIC\" && rostopic list 2>/dev/null | grep -qx \"$UAV_IMU_TOPIC\"; do echo \"[wait] UAV sensor topics\"; sleep 1; done"
WAIT_FOR_UAV_LIO_OUTPUTS="until rostopic list 2>/dev/null | grep -qx \"$UAV_CLOUD_BODY_TOPIC\" && timeout ${LIO_OUTPUT_ECHO_TIMEOUT}s rostopic echo -n 1 \"$UAV_ODOM_TOPIC\" >/dev/null 2>&1; do echo \"[wait] UAV Super-LIO cloud and odom output\"; sleep 1; done"
WAIT_FOR_GAZEBO='until rosservice list 2>/dev/null | grep -qx "/gazebo/spawn_urdf_model"; do echo "[wait] Gazebo spawn service"; sleep 1; done'
WAIT_FOR_UGV_SENSORS="until rostopic list 2>/dev/null | grep -qx \"$UGV_LIDAR_TOPIC\" && rostopic list 2>/dev/null | grep -qx \"$UGV_IMU_TOPIC\"; do echo \"[wait] UGV sensor topics\"; sleep 1; done"
WAIT_FOR_UGV_LIO_OUTPUTS="until rostopic list 2>/dev/null | grep -qx \"$UGV_CLOUD_BODY_TOPIC\" && timeout ${LIO_OUTPUT_ECHO_TIMEOUT}s rostopic echo -n 1 \"$UGV_ODOM_TOPIC\" >/dev/null 2>&1; do echo \"[wait] UGV Super-LIO cloud and odom output\"; sleep 1; done"
WAIT_FOR_UGV_CMU_INPUTS="until rostopic list 2>/dev/null | grep -qx \"$UGV_CMU_SCAN_TOPIC\" && timeout ${LIO_OUTPUT_ECHO_TIMEOUT}s rostopic echo -n 1 \"$UGV_CMU_STATE_TOPIC\" >/dev/null 2>&1; do echo \"[wait] UGV CMU planner scan and odom input\"; sleep 1; done"
WAIT_FOR_HUSKY_SENSORS="until rostopic list 2>/dev/null | grep -qx \"$HUSKY_LIDAR_TOPIC\" && rostopic list 2>/dev/null | grep -qx \"$HUSKY_IMU_TOPIC\"; do echo \"[wait] Husky sensor topics\"; sleep 1; done"
WAIT_FOR_HUSKY_LIO_OUTPUTS="until rostopic list 2>/dev/null | grep -qx \"$HUSKY_CLOUD_BODY_TOPIC\" && timeout ${LIO_OUTPUT_ECHO_TIMEOUT}s rostopic echo -n 1 \"$HUSKY_ODOM_TOPIC\" >/dev/null 2>&1; do echo \"[wait] Husky Super-LIO cloud and odom output\"; sleep 1; done"
WAIT_FOR_HUSKY_CMU_INPUTS="until rostopic list 2>/dev/null | grep -qx \"$HUSKY_CMU_SCAN_TOPIC\" && timeout ${LIO_OUTPUT_ECHO_TIMEOUT}s rostopic echo -n 1 \"$HUSKY_CMU_STATE_TOPIC\" >/dev/null 2>&1; do echo \"[wait] Husky CMU planner scan and odom input\"; sleep 1; done"
WAIT_FOR_UAV_CAMERA="until rostopic list 2>/dev/null | grep -qx \"$UAV_YOLO_IMAGE_TOPIC\" && timeout 10s rostopic echo -n 1 \"$UAV_YOLO_IMAGE_TOPIC\" >/dev/null 2>&1; do echo \"[wait] UAV RGB camera image\"; sleep 1; done"
WAIT_FOR_UGV_CAMERA="until rostopic list 2>/dev/null | grep -qx \"$UGV_YOLO_IMAGE_TOPIC\" && timeout 10s rostopic echo -n 1 \"$UGV_YOLO_IMAGE_TOPIC\" >/dev/null 2>&1; do echo \"[wait] UGV RGB camera image\"; sleep 1; done"
WAIT_FOR_HUSKY_CAMERA="until rostopic list 2>/dev/null | grep -qx \"$HUSKY_YOLO_IMAGE_TOPIC\" && timeout 10s rostopic echo -n 1 \"$HUSKY_YOLO_IMAGE_TOPIC\" >/dev/null 2>&1; do echo \"[wait] Husky RGB camera image\"; sleep 1; done"

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

prepare_camera_assets() {
  if [[ "$UAV_ENABLE_CAMERA" == "true" ]]; then
    local generator="$WS/src/mrm_run_launch/scripts/inject_uav_camera_sdf.py"
    if [[ ! -x "$generator" ]]; then
      echo "[camera][ERROR] missing UAV camera SDF generator: $generator" >&2
      return 1
    fi
    if [[ -z "$PX4_UAV_SDF" || ! -f "$PX4_UAV_SDF" ]]; then
      echo "[camera][ERROR] PX4 UAV SDF not found before camera injection. Set PX4_UAV_SDF=/path/to/model.sdf" >&2
      return 1
    fi
    mkdir -p "$(dirname "$UAV_CAMERA_SDF")"
    python3 "$generator" \
      --source "$PX4_UAV_SDF" \
      --output "$UAV_CAMERA_SDF" \
      --robot-namespace "$UAV_MOCHA_ROBOT"
    PX4_UAV_SDF="$UAV_CAMERA_SDF"
    echo "[camera] UAV RGB camera SDF: $PX4_UAV_SDF"
  fi

  if [[ "$UGV_ENABLE_CAMERA" == "true" ]]; then
    if [[ ! -f "$UGV_CAMERA_URDF_EXTRAS" ]]; then
      echo "[camera][ERROR] Jackal camera URDF extras not found: $UGV_CAMERA_URDF_EXTRAS" >&2
      return 1
    fi
    echo "[camera] Jackal RGB camera extras: $UGV_CAMERA_URDF_EXTRAS"
  fi

  if [[ "$HUSKY_ENABLE_CAMERA" == "true" ]]; then
    if [[ ! -f "$HUSKY_CAMERA_URDF_EXTRAS" ]]; then
      echo "[camera][ERROR] Husky camera URDF extras not found: $HUSKY_CAMERA_URDF_EXTRAS" >&2
      return 1
    fi
    echo "[camera] Husky RGB camera extras: $HUSKY_CAMERA_URDF_EXTRAS"
  fi
}
