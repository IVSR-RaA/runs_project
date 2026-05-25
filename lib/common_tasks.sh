#!/usr/bin/env bash
# lib/common_tasks.sh
# Common runtime helpers and manual shells.

start_status_window() {
  tmux send-keys -t "$SESSION:00_status.0" "clear; cat <<'EOF'
Multi-Robot Mapping Runtime Session

Session: $SESSION
State directory: $SESSION_STATE_DIR
Run only: $RUN_ONLY
LAMP mode: $LAMP_MODE

ROS masters:
  UAV:  $UAV_MASTER_URI
  UGV:  $UGV_MASTER_URI
  Base: $BASE_MASTER_URI

Gazebo masters:
  UAV: $UAV_GAZEBO_MASTER_URI
  UGV: $UGV_GAZEBO_MASTER_URI

Names:
  UAV MOCHA=$UAV_MOCHA_ROBOT, LAMP=$UAV_LAMP_ROBOT, lidar=$UAV_LIDAR_TOPIC, odom=$UAV_ODOM_TOPIC
  UGV MOCHA=$UGV_MOCHA_ROBOT, LAMP=$UGV_LAMP_ROBOT, lidar=$UGV_LIDAR_TOPIC, odom=$UGV_ODOM_TOPIC
  Distributed fusion namespaces: UAV=$UAV_FUSION_NAMESPACE, UGV=$UGV_FUSION_NAMESPACE
  Simulation world: $SIM_WORLD_FILE

Runtime windows:
  01_uav_run     UAV runtime
  02_ugv_run     UGV runtime
  03_base_run    Base station runtime, only in base mode
  04_uav_manual  Six UAV manual shells, if UAV is running
  05_ugv_manual  Six UGV manual shells, if UGV is running
  06_base_manual Six base manual shells, if base is running

Stop:
  ./run/run_mrm.sh --kill

EOF
exec bash" C-m
}

distributed_base1_compat_relays() {
  local fusion_namespace="$1"
  local relay_prefix="$2"

  printf '%s' "rosrun topic_tools relay /$fusion_namespace/lamp/keyed_scans /base1/lamp/keyed_scans __name:=${relay_prefix}_keyed_scans_to_base1 & "
  printf '%s' "rosrun topic_tools relay /$fusion_namespace/lamp/pose_graph /base1/lamp/pose_graph __name:=${relay_prefix}_pose_graph_to_base1 & "
  printf '%s' "rosrun topic_tools relay /$fusion_namespace/lamp/octree_map /base1/lamp/octree_map __name:=${relay_prefix}_octree_map_to_base1 & "
  printf '%s' "rosrun topic_tools relay /$fusion_namespace/lamp_pgo/optimized_values /base1/lamp_pgo/optimized_values __name:=${relay_prefix}_optimized_values_to_base1 & "
  printf '%s' "rosrun topic_tools relay /$fusion_namespace/pose_graph_visualizer/odometry_edges /base1/pose_graph_visualizer/odometry_edges __name:=${relay_prefix}_odometry_edges_to_base1 & "
  printf '%s' "rosrun topic_tools relay /$fusion_namespace/pose_graph_visualizer/loop_edges /base1/pose_graph_visualizer/loop_edges __name:=${relay_prefix}_loop_edges_to_base1 & "
}

start_manual_window() {
  local window="$1"
  local ros_env="$2"
  local label="$3"

  make_window "$window" 6
  for pane in 0 1 2 3 4 5; do
    send_plain "$SESSION:$window.$pane" "$COMMON_SETUP" "$ros_env" "echo '$label manual shell $pane'; echo 'ROS_MASTER_URI='\"\$ROS_MASTER_URI\"; echo 'ROS_IP='\"\$ROS_IP\"; echo 'GAZEBO_MASTER_URI='\"\${GAZEBO_MASTER_URI:-}\"; exec bash" false
  done
}

start_manual_shells() {
  if [[ "$RUN_UAV_GROUP" == "true" ]]; then
    start_manual_window "04_uav_manual" "$UAV_ROS_ENV" "UAV"
  fi

  if [[ "$RUN_UGV_GROUP" == "true" ]]; then
    start_manual_window "05_ugv_manual" "$UGV_ROS_ENV" "UGV"
  fi

  if [[ "$RUN_BASE_GROUP" == "true" ]]; then
    start_manual_window "06_base_manual" "$BASE_ROS_ENV" "Base"
  fi
}
