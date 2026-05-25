#!/usr/bin/env bash
# lib/common_tasks.sh
# Common tasks: status, visual tools, ROS diagnostics, manual shells

start_status_window() {
  tmux send-keys -t "$SESSION:00_status.0" "clear; cat <<'EOF'
Multi-Robot Mapping Debug Session

Session: $SESSION
State directory: $SESSION_STATE_DIR
Run only: $RUN_ONLY
LAMP mode: $LAMP_MODE

Names:
  UAV MOCHA=$UAV_MOCHA_ROBOT, LAMP=$UAV_LAMP_ROBOT, lidar=$UAV_LIDAR_TOPIC
  UGV MOCHA=$UGV_MOCHA_ROBOT, LAMP=$UGV_LAMP_ROBOT, lidar=$UGV_LIDAR_TOPIC
  Distributed fusion namespaces: UAV=$UAV_FUSION_NAMESPACE, UGV=$UGV_FUSION_NAMESPACE
  Simulation world: $SIM_WORLD_FILE
  UAV spawn=($UAV_SPAWN_X, $UAV_SPAWN_Y, $UAV_SPAWN_Z), map=($UAV_MAP_X, $UAV_MAP_Y, $UAV_MAP_Z)
  UGV spawn=($UGV_SPAWN_X, $UGV_SPAWN_Y, $UGV_SPAWN_Z), map=($UGV_MAP_X, $UGV_MAP_Y, $UGV_MAP_Z)
  UAV ROS=$UAV_MASTER_URI, Gazebo=$UAV_GAZEBO_MASTER_URI
  UGV ROS=$UGV_MASTER_URI, Gazebo=$UGV_GAZEBO_MASTER_URI
  Base ROS=$BASE_MASTER_URI
  Gazebo GUI master=$VISUAL_GAZEBO_MASTER_URI

Windows:
  01_uav_run   UAV runtime
  02_ugv_run   UGV runtime
  03_base_run  Base station runtime
  04_uav_mon   UAV monitors
  05_ugv_mon   UGV monitors
  06_base_mon  Base station monitors
  07_visual    RViz/rqt/Gazebo GUI tools
  08_ros_diag  roswtf, rosnode, and rostopic diagnostics
  09_manual    Manual ROS debug shells
  10_rssi_mon  RSSI topics and rates

No run log files are written. Runtime stdout/stderr stays in the tmux panes.

Stop:
  $0 --kill

EOF
exec bash" C-m
}

start_distributed_lamp_fusion() {
  local pane="$1"
  local ros_env="$2"
  local fusion_namespace="$3"
  local relay_prefix="$4"
  local relay_commands=(
    "rosrun topic_tools relay /$fusion_namespace/lamp/keyed_scans /base1/lamp/keyed_scans __name:=${relay_prefix}_keyed_scans_to_base1"
    "rosrun topic_tools relay /$fusion_namespace/lamp/pose_graph /base1/lamp/pose_graph __name:=${relay_prefix}_pose_graph_to_base1"
    "rosrun topic_tools relay /$fusion_namespace/lamp/octree_map /base1/lamp/octree_map __name:=${relay_prefix}_octree_map_to_base1"
    "rosrun topic_tools relay /$fusion_namespace/lamp_pgo/optimized_values /base1/lamp_pgo/optimized_values __name:=${relay_prefix}_optimized_values_to_base1"
    "rosrun topic_tools relay /$fusion_namespace/pose_graph_visualizer/odometry_edges /base1/pose_graph_visualizer/odometry_edges __name:=${relay_prefix}_odometry_edges_to_base1"
    "rosrun topic_tools relay /$fusion_namespace/pose_graph_visualizer/loop_edges /base1/pose_graph_visualizer/loop_edges __name:=${relay_prefix}_loop_edges_to_base1"
  )
  local launch_command="rosparam load '$BASE_LAMP_ROBOT_NAMES_CONFIG' /base1/lamp; "
  local relay_command

  for relay_command in "${relay_commands[@]}"; do
    launch_command+="$relay_command & "
  done
  launch_command+="roslaunch lamp turn_on_lamp_base.launch robot_namespace:=$fusion_namespace robot_names_config:='$BASE_LAMP_ROBOT_NAMES_CONFIG' rssi_parameters_config:='$BASE_RSSI_PARAMETERS_CONFIG' run_loop_closure_batcher:=$RUN_GNN_BATCHER"

  send_plain "$pane" "$COMMON_SETUP" "$ros_env" "$launch_command"
}

start_visual_tools() {
  local uav_rviz_config="$RVIZ_CONFIG"
  local ugv_rviz_config="$RVIZ_CONFIG"
  if [[ "$LAMP_MODE" == "base" ]]; then
    ugv_rviz_config="$UGV_RVIZ_CONFIG"
  fi

  make_window "07_visual" 10
  send_plain "$SESSION:07_visual.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "rviz -d '$uav_rviz_config'"
  send_plain "$SESSION:07_visual.1" "$COMMON_SETUP" "$UGV_ROS_ENV" "rviz -d '$ugv_rviz_config'"
  send_plain "$SESSION:07_visual.2" "$COMMON_SETUP" "$UAV_ROS_ENV" "rqt_graph"
  send_plain "$SESSION:07_visual.3" "$COMMON_SETUP" "$UGV_ROS_ENV" "rqt_graph"
  send_plain "$SESSION:07_visual.4" "$COMMON_SETUP" "$UAV_ROS_ENV" "rosrun rqt_tf_tree rqt_tf_tree"
  send_plain "$SESSION:07_visual.5" "$COMMON_SETUP" "$UGV_ROS_ENV" "rosrun rqt_tf_tree rqt_tf_tree"
  send_plain "$SESSION:07_visual.6" "$COMMON_SETUP" "$UAV_ROS_ENV" "rqt_console"
  send_plain "$SESSION:07_visual.7" "$COMMON_SETUP" "$UGV_ROS_ENV" "rqt_console"
  send_plain "$SESSION:07_visual.8" "$COMMON_SETUP" "$UAV_ROS_ENV; export GAZEBO_MASTER_URI=$UAV_GAZEBO_MASTER_URI" "gzclient" false
  send_plain "$SESSION:07_visual.9" "$COMMON_SETUP" "$UGV_ROS_ENV; export GAZEBO_MASTER_URI=$UGV_GAZEBO_MASTER_URI" "gzclient" false
}

start_base_visual_tools() {
  make_window "07_visual" 4
  send_plain "$SESSION:07_visual.0" "$COMMON_SETUP" "$BASE_ROS_ENV" "rviz -d '$RVIZ_CONFIG'"
  send_plain "$SESSION:07_visual.1" "$COMMON_SETUP" "$BASE_ROS_ENV" "rqt_graph"
  send_plain "$SESSION:07_visual.2" "$COMMON_SETUP" "$BASE_ROS_ENV" "rosrun rqt_tf_tree rqt_tf_tree"
  send_plain "$SESSION:07_visual.3" "$COMMON_SETUP" "$BASE_ROS_ENV" "rqt_console"
}

start_uav_visual_tools() {
  make_window "07_visual" 5
  send_plain "$SESSION:07_visual.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "rviz -d '$RVIZ_CONFIG'"
  send_plain "$SESSION:07_visual.1" "$COMMON_SETUP" "$UAV_ROS_ENV; $VISUAL_GAZEBO_ENV" "gzclient" false
  send_plain "$SESSION:07_visual.2" "$COMMON_SETUP" "$UAV_ROS_ENV" "rqt_graph"
  send_plain "$SESSION:07_visual.3" "$COMMON_SETUP" "$UAV_ROS_ENV" "rosrun rqt_tf_tree rqt_tf_tree"
  send_plain "$SESSION:07_visual.4" "$COMMON_SETUP" "$UAV_ROS_ENV" "rqt_console"
}

start_ugv_visual_tools() {
  local rviz_config="$RVIZ_CONFIG"
  if [[ "$LAMP_MODE" == "base" ]]; then
    rviz_config="$UGV_RVIZ_CONFIG"
  fi

  make_window "07_visual" 5
  send_plain "$SESSION:07_visual.0" "$COMMON_SETUP" "$UGV_ROS_ENV" "rviz -d '$rviz_config'"
  send_plain "$SESSION:07_visual.1" "$COMMON_SETUP" "$UGV_ROS_ENV" "gzclient" false
  send_plain "$SESSION:07_visual.2" "$COMMON_SETUP" "$UGV_ROS_ENV" "rqt_graph"
  send_plain "$SESSION:07_visual.3" "$COMMON_SETUP" "$UGV_ROS_ENV" "rosrun rqt_tf_tree rqt_tf_tree"
  send_plain "$SESSION:07_visual.4" "$COMMON_SETUP" "$UGV_ROS_ENV" "rqt_console"
}

start_rssi_monitors() {
  local monitor_cmd="watch -n 1 bash '$SCRIPT_DIR/lib/monitor_rssi.sh' $RSSI_ROBOTS"
  local hz_topics="/ddb/tplink/rssi/$UAV_MOCHA_ROBOT /ddb/tplink/rssi/$UGV_MOCHA_ROBOT"
  if [[ "$LAMP_MODE" != "distributed" ]]; then
    hz_topics="$hz_topics /ddb/tplink/rssi/basestation"
  fi
  local hz_cmd="rostopic hz $hz_topics"
  local loop_cmd="watch -n 2 \"rostopic list | grep -E 'rssi_loop|rssi_markers|status_agg|prioritized_loop_candidates|comm_node_manager|/ddb/tplink/rssi' || true\""

  case "$RUN_ONLY" in
    all)
      if [[ "$LAMP_MODE" == "distributed" ]]; then
        make_window "10_rssi_mon" 4
        send_plain "$SESSION:10_rssi_mon.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "$monitor_cmd"
        send_plain "$SESSION:10_rssi_mon.1" "$COMMON_SETUP" "$UGV_ROS_ENV" "$monitor_cmd"
        send_plain "$SESSION:10_rssi_mon.2" "$COMMON_SETUP" "$UAV_ROS_ENV" "$hz_cmd"
        send_plain "$SESSION:10_rssi_mon.3" "$COMMON_SETUP" "$UGV_ROS_ENV" "$hz_cmd"
      else
        make_window "10_rssi_mon" 5
        send_plain "$SESSION:10_rssi_mon.0" "$COMMON_SETUP" "$BASE_ROS_ENV" "$monitor_cmd"
        send_plain "$SESSION:10_rssi_mon.1" "$COMMON_SETUP" "$UAV_ROS_ENV" "$monitor_cmd"
        send_plain "$SESSION:10_rssi_mon.2" "$COMMON_SETUP" "$UGV_ROS_ENV" "$monitor_cmd"
        send_plain "$SESSION:10_rssi_mon.3" "$COMMON_SETUP" "$BASE_ROS_ENV" "$hz_cmd"
        send_plain "$SESSION:10_rssi_mon.4" "$COMMON_SETUP" "$BASE_ROS_ENV" "$loop_cmd"
      fi
      ;;
    uav)
      make_window "10_rssi_mon" 2
      send_plain "$SESSION:10_rssi_mon.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "$monitor_cmd"
      send_plain "$SESSION:10_rssi_mon.1" "$COMMON_SETUP" "$UAV_ROS_ENV" "$hz_cmd"
      ;;
    ugv)
      make_window "10_rssi_mon" 2
      send_plain "$SESSION:10_rssi_mon.0" "$COMMON_SETUP" "$UGV_ROS_ENV" "$monitor_cmd"
      send_plain "$SESSION:10_rssi_mon.1" "$COMMON_SETUP" "$UGV_ROS_ENV" "$hz_cmd"
      ;;
    base)
      make_window "10_rssi_mon" 3
      send_plain "$SESSION:10_rssi_mon.0" "$COMMON_SETUP" "$BASE_ROS_ENV" "$monitor_cmd"
      send_plain "$SESSION:10_rssi_mon.1" "$COMMON_SETUP" "$BASE_ROS_ENV" "$hz_cmd"
      send_plain "$SESSION:10_rssi_mon.2" "$COMMON_SETUP" "$BASE_ROS_ENV" "$loop_cmd"
      ;;
  esac
}

start_ros_diag_windows() {
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    make_window "08_ros_diag" 4
    send_plain "$SESSION:08_ros_diag.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "watch -n 2 \"rostopic list | sort | grep -E 'keyframe|vae|lio|lamp|ddb|rssi|reconstructed|octvox|cloud|tf|gazebo' || true\""
    send_plain "$SESSION:08_ros_diag.1" "$COMMON_SETUP" "$UGV_ROS_ENV" "watch -n 2 \"rostopic list | sort | grep -E 'keyframe|vae|lio|lamp|ddb|rssi|reconstructed|octvox|cloud|tf|gazebo' || true\""
    send_plain "$SESSION:08_ros_diag.2" "$COMMON_SETUP" "$UAV_ROS_ENV" "watch -n 5 roswtf"
    send_plain "$SESSION:08_ros_diag.3" "$COMMON_SETUP" "$UGV_ROS_ENV" "watch -n 5 roswtf"
  else
    make_window "08_ros_diag" 6
    send_plain "$SESSION:08_ros_diag.0" "$COMMON_SETUP" "$BASE_ROS_ENV" "watch -n 2 \"rostopic list | sort | grep -E 'keyframe|vae|lio|lamp|ddb|rssi|reconstructed|octvox|cloud|tf|gazebo|optimized' || true\""
    send_plain "$SESSION:08_ros_diag.1" "$COMMON_SETUP" "$UAV_ROS_ENV" "watch -n 2 \"rostopic list | sort | grep -E 'keyframe|vae|lio|lamp|ddb|rssi|reconstructed|octvox|cloud|tf|gazebo' || true\""
    send_plain "$SESSION:08_ros_diag.2" "$COMMON_SETUP" "$UGV_ROS_ENV" "watch -n 2 \"rostopic list | sort | grep -E 'keyframe|vae|lio|lamp|ddb|rssi|reconstructed|octvox|cloud|tf|gazebo' || true\""
    send_plain "$SESSION:08_ros_diag.3" "$COMMON_SETUP" "$UAV_ROS_ENV" "watch -n 5 roswtf"
    send_plain "$SESSION:08_ros_diag.4" "$COMMON_SETUP" "$UGV_ROS_ENV" "watch -n 5 roswtf"
    send_plain "$SESSION:08_ros_diag.5" "$COMMON_SETUP" "$BASE_ROS_ENV" "watch -n 5 roswtf"
  fi
}

start_selected_ros_diag_windows() {
  local ros_env

  if [[ "$RUN_ONLY" == "all" ]]; then
    start_ros_diag_windows
    return
  fi

  case "$RUN_ONLY" in
    uav) ros_env="$UAV_ROS_ENV" ;;
    ugv) ros_env="$UGV_ROS_ENV" ;;
    base) ros_env="$BASE_ROS_ENV" ;;
  esac

  make_window "08_ros_diag" 3
  send_plain "$SESSION:08_ros_diag.0" "$COMMON_SETUP" "$ros_env" "watch -n 2 \"rostopic list | sort | grep -E 'keyframe|vae|lio|lamp|ddb|rssi|reconstructed|octvox|cloud|tf|gazebo|optimized' || true\""
  send_plain "$SESSION:08_ros_diag.1" "$COMMON_SETUP" "$ros_env" "watch -n 2 \"rosnode list | sort | grep -E 'mocha|super|vae|lamp|keyframe|tf|rssi|gazebo|rviz|rqt' || true\""
  send_plain "$SESSION:08_ros_diag.2" "$COMMON_SETUP" "$ros_env" "watch -n 5 roswtf"
}

start_manual_shells() {
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    make_window "09_manual" 3
    send_plain "$SESSION:09_manual.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "echo 'UAV shell: rostopic info /keyframe_vae; rostopic info /$UAV_FUSION_NAMESPACE/lamp/pose_graph; rosnode list'; exec bash" false
    send_plain "$SESSION:09_manual.1" "$COMMON_SETUP" "$UGV_ROS_ENV" "echo 'UGV shell: rostopic info /keyframe_vae; rostopic info /$UGV_FUSION_NAMESPACE/lamp/pose_graph; rosnode list'; exec bash" false
    send_plain "$SESSION:09_manual.2" "$COMMON_SETUP" "$UAV_ROS_ENV" "echo 'Manual shell: rostopic list; rosnode list; roswtf'; exec bash" false
  else
    make_window "09_manual" 3
    send_plain "$SESSION:09_manual.0" "$COMMON_SETUP" "$BASE_ROS_ENV" "echo 'Base shell: rostopic info /$UGV_MOCHA_ROBOT/keyframe_vae; rostopic echo --noarr /base1/lamp/pose_graph; rosnode info /base1/lamp'; exec bash" false
    send_plain "$SESSION:09_manual.1" "$COMMON_SETUP" "$UAV_ROS_ENV" "echo 'UAV shell: rostopic info /keyframe_vae; rosnode info /$UAV_MOCHA_ROBOT/vae_keyframe_generator'; exec bash" false
    send_plain "$SESSION:09_manual.2" "$COMMON_SETUP" "$UGV_ROS_ENV" "echo 'UGV shell: rostopic info /keyframe_vae; rosnode info /$UGV_MOCHA_ROBOT/vae_keyframe_generator'; exec bash" false
  fi
}

start_selected_manual_shells() {
  if [[ "$RUN_ONLY" == "all" ]]; then
    start_manual_shells
    return
  fi

  make_window "09_manual" 1
  case "$RUN_ONLY" in
    uav) send_plain "$SESSION:09_manual.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "echo 'UAV shell: rostopic info /keyframe_vae; rosnode list'; exec bash" false ;;
    ugv) send_plain "$SESSION:09_manual.0" "$COMMON_SETUP" "$UGV_ROS_ENV" "echo 'UGV shell: rostopic info /keyframe_vae; rostopic list; rosnode list'; exec bash" false ;;
    base) send_plain "$SESSION:09_manual.0" "$COMMON_SETUP" "$BASE_ROS_ENV" "echo 'Base shell: rostopic list; rosnode list'; exec bash" false ;;
  esac
}
