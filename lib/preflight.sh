#!/usr/bin/env bash
# lib/preflight.sh
# Preflight checks and configuration generators

preflight_checks() {
  local missing=0
  local pkg
  local required_pkgs=(
    mocha_launch
    mocha_core
    super_lio_lamp_adapter
    tf
    rqt_tf_tree
  )
  local optional_commands=(
    rviz
    rqt_graph
    rqt_console
    gzclient
  )

  if [[ "$RUN_ONLY" == "all" || "$RUN_ONLY" == "uav" ]]; then
    required_pkgs+=(geometric_controller mavlink_sitl_gazebo mavros px4 super_lio)
  fi

  if [[ "$RUN_ONLY" == "all" || "$RUN_ONLY" == "ugv" ]]; then
    required_pkgs+=(super_lio)
  fi

  if [[ "$RUN_ONLY" == "all" || "$RUN_ONLY" == "base" || "$LAMP_MODE" == "distributed" ]]; then
    required_pkgs+=(lamp)
  fi

  if [[ "$LAMP_MODE" == "distributed" ]]; then
    required_pkgs+=(topic_tools)
  fi

  echo "[preflight] checking ROS packages..."
  for pkg in "${required_pkgs[@]}"; do
    if ! bash -lc "$PREFLIGHT_SETUP; rospack find '$pkg'" >/dev/null 2>&1; then
      echo "[preflight][ERROR] missing ROS package: $pkg" >&2
      missing=1
    fi
  done

  echo "[preflight] checking optional GUI commands..."
  for cmd in "${optional_commands[@]}"; do
    if ! bash -lc "$PREFLIGHT_SETUP; command -v '$cmd'" >/dev/null 2>&1; then
      echo "[preflight][WARN] optional GUI command not found: $cmd" >&2
    fi
  done

  if [[ ("$RUN_ONLY" == "all" || "$RUN_ONLY" == "uav") && -z "$PX4_UAV_SDF" ]]; then
    echo "[preflight][ERROR] PX4 UAV SDF not found. Set PX4_UAV_SDF=/path/to/model.sdf" >&2
    missing=1
  fi

  if [[ ! -f "$RVIZ_CONFIG" ]]; then
    echo "[preflight][WARN] RViz config not found: $RVIZ_CONFIG" >&2
  fi

  if [[ ("$RUN_ONLY" == "all" || "$RUN_ONLY" == "uav" || "$RUN_ONLY" == "ugv") && ! -f "$SIM_WORLD_FILE" ]]; then
    echo "[preflight][ERROR] simulation world file not found: $SIM_WORLD_FILE" >&2
    echo "[preflight][ERROR] set SIM_WORLD_FILE=/path/to/world.world if you want a different world." >&2
    missing=1
  fi

  return "$missing"
}

validate_runtime_isolation() {
  local failed=0

  if [[ "$RUN_UAV_GROUP" == "true" && "$RUN_UGV_GROUP" == "true" ]]; then
    if [[ "$UAV_MASTER_URI" == "$UGV_MASTER_URI" ]]; then
      echo "[config][ERROR] UAV_MASTER_URI and UGV_MASTER_URI must differ when running both robots." >&2
      echo "[config][ERROR] shared ROS master mixes global topics such as /lio/odom and /keyframe_vae." >&2
      failed=1
    fi

    if [[ "$UAV_GAZEBO_MASTER_URI" == "$UGV_GAZEBO_MASTER_URI" ]]; then
      echo "[config][ERROR] UAV_GAZEBO_MASTER_URI and UGV_GAZEBO_MASTER_URI must differ when running both robots." >&2
      echo "[config][ERROR] use separate Gazebo masters, for example 11345 for UAV and 11346 for UGV." >&2
      failed=1
    fi
  fi

  return "$failed"
}

ensure_loopback_alias() {
  local cidr="$1"
  local ip="${cidr%/*}"

  if ip -o addr show dev lo | grep -q "inet $ip/"; then
    echo "[net] loopback IP exists: $ip"
  else
    echo "[net] adding loopback alias with sudo: $cidr"
    echo "[net] enter your sudo password if prompted."
    if ! sudo ip addr add "$cidr" dev lo; then
      echo "[net][ERROR] failed to add loopback alias: $cidr" >&2
      return 1
    fi
  fi
}

prepare_mocha_config_arg() {
  if [[ -z "$MOCHA_ROBOT_CONFIG" ]]; then
    MOCHA_ROBOT_CONFIG="$SESSION_STATE_DIR/mocha_robot_configs.yaml"
    mkdir -p "$(dirname "$MOCHA_ROBOT_CONFIG")"
    if [[ "$LAMP_MODE" == "distributed" ]]; then
      cat >"$MOCHA_ROBOT_CONFIG" <<EOF
$UGV_MOCHA_ROBOT:
  node-type: "ground_robot"
  IP-address: "$UGV_IP"
  using-radio: "radio_ugv"
  base-port: "2234"
  clients:
    - "$UAV_MOCHA_ROBOT"

$UAV_MOCHA_ROBOT:
  node-type: "aerial_robot"
  IP-address: "$UAV_IP"
  using-radio: "radio_uav"
  base-port: "6234"
  clients:
    - "$UGV_MOCHA_ROBOT"
EOF
    else
      cat >"$MOCHA_ROBOT_CONFIG" <<EOF
basestation:
  node-type: "base_station"
  IP-address: "$BASE_IP"
  using-radio: "radio_base"
  base-port: "1234"
  clients:
    - "$UGV_MOCHA_ROBOT"
    - "$UAV_MOCHA_ROBOT"

$UGV_MOCHA_ROBOT:
  node-type: "ground_robot"
  IP-address: "$UGV_IP"
  using-radio: "radio_ugv"
  base-port: "2234"
  clients:
    - "$UAV_MOCHA_ROBOT"
    - "basestation"

$UAV_MOCHA_ROBOT:
  node-type: "aerial_robot"
  IP-address: "$UAV_IP"
  using-radio: "radio_uav"
  base-port: "6234"
  clients:
    - "$UGV_MOCHA_ROBOT"
    - "basestation"
EOF
    fi
  fi

  MOCHA_ROBOT_CONFIG_ARG="robot_configs:=$MOCHA_ROBOT_CONFIG"
}

prepare_lamp_robot_names_config() {
  if [[ -z "$BASE_LAMP_ROBOT_NAMES_CONFIG" ]]; then
    BASE_LAMP_ROBOT_NAMES_CONFIG="$SESSION_STATE_DIR/lamp_robot_names.yaml"
  fi

  mkdir -p "$(dirname "$BASE_LAMP_ROBOT_NAMES_CONFIG")"
  cat >"$BASE_LAMP_ROBOT_NAMES_CONFIG" <<EOF
robot_names:
  - '$UAV_LAMP_ROBOT'
  - '$UGV_LAMP_ROBOT'
EOF
}

prepare_base_rssi_parameters_config() {
  if [[ -z "$BASE_RSSI_PARAMETERS_CONFIG" ]]; then
    BASE_RSSI_PARAMETERS_CONFIG="$SESSION_STATE_DIR/rssi_parameters.yaml"
  fi

  mkdir -p "$(dirname "$BASE_RSSI_PARAMETERS_CONFIG")"
  cat >"$BASE_RSSI_PARAMETERS_CONFIG" <<EOF
update_rate: 1.0
acceptable_shortest_rssi_distance: 60
robots_loop_closure: ['$UAV_LAMP_ROBOT', '$UGV_LAMP_ROBOT']
radio_loop_closure_method: "nodes_to_nodes"
close_keys_threshold: 20
EOF
}
