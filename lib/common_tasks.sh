#!/usr/bin/env bash
# lib/common_tasks.sh
# Common tasks: status, visual tools, logs, manual shells

start_status_window() {
  tmux send-keys -t "$SESSION:00_status.0" "clear; cat <<'EOF'
Multi-Robot Mapping Debug Session

Session: $SESSION
Log directory: $LOG_DIR
Run only: $RUN_ONLY
LAMP mode: $LAMP_MODE

Names:
  UAV MOCHA=$UAV_MOCHA_ROBOT, LAMP=$UAV_LAMP_ROBOT, lidar=$UAV_LIDAR_TOPIC
  UGV MOCHA=$UGV_MOCHA_ROBOT, LAMP=$UGV_LAMP_ROBOT, lidar=$UGV_LIDAR_TOPIC
  Distributed fusion namespaces: UAV=$UAV_FUSION_NAMESPACE, UGV=$UGV_FUSION_NAMESPACE
  Simulation world: $SIM_WORLD_FILE
  Gazebo GUI master=$VISUAL_GAZEBO_MASTER_URI

Windows:
  01_uav_run   UAV runtime
  02_ugv_run   UGV runtime
  03_base_run  Base station runtime
  04_uav_mon   UAV monitors
  05_ugv_mon   UGV monitors
  06_base_mon  Base station monitors
  07_visual    RViz/rqt/Gazebo GUI tools
  08_logs      Logs, errors, roswtf
  09_manual    Manual debug shells
  10_rssi_mon  RSSI topics, rates, and logs

Stop:
  $0 --kill

EOF
tail -F '$LOG_DIR'/*.log 2>/dev/null" C-m
}

start_visual_tools() {
  local visual_ros_env="$BASE_ROS_ENV"
  local visual_gazebo_env="$VISUAL_GAZEBO_ENV"
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    if [[ "$DISTRIBUTED_VISUAL_ROBOT" == "ugv" ]]; then
      visual_ros_env="$UGV_ROS_ENV"
      visual_gazebo_env="export GAZEBO_MASTER_URI=$UGV_GAZEBO_MASTER_URI"
    else
      visual_ros_env="$UAV_ROS_ENV"
      visual_gazebo_env="export GAZEBO_MASTER_URI=$UAV_GAZEBO_MASTER_URI"
    fi
  fi

  make_window "07_visual" 5
  send_plain "$SESSION:07_visual.0" "$COMMON_SETUP" "$visual_ros_env" "rviz -d '$RVIZ_CONFIG'"
  send_plain "$SESSION:07_visual.1" "$COMMON_SETUP" "$visual_ros_env" "rqt_graph"
  send_plain "$SESSION:07_visual.2" "$COMMON_SETUP" "$visual_ros_env" "rosrun rqt_tf_tree rqt_tf_tree"
  send_plain "$SESSION:07_visual.3" "$COMMON_SETUP" "$visual_ros_env" "rqt_console"
  send_plain "$SESSION:07_visual.4" "$COMMON_SETUP" "$visual_ros_env; $visual_gazebo_env" "gzclient" false
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
  make_window "07_visual" 5
  send_plain "$SESSION:07_visual.0" "$COMMON_SETUP" "$UGV_ROS_ENV" "rviz -d '$RVIZ_CONFIG'"
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
  local log_cmd="tail -F '$LOG_DIR'/*rssi*.log 2>/dev/null"

  case "$RUN_ONLY" in
    all)
      if [[ "$LAMP_MODE" == "distributed" ]]; then
        make_window "10_rssi_mon" 5
        send_plain "$SESSION:10_rssi_mon.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "$monitor_cmd"
        send_plain "$SESSION:10_rssi_mon.1" "$COMMON_SETUP" "$UGV_ROS_ENV" "$monitor_cmd"
        send_plain "$SESSION:10_rssi_mon.2" "$COMMON_SETUP" "$UAV_ROS_ENV" "$hz_cmd"
        send_plain "$SESSION:10_rssi_mon.3" "$COMMON_SETUP" "$UGV_ROS_ENV" "$hz_cmd"
        send_plain "$SESSION:10_rssi_mon.4" "$COMMON_SETUP" "$UAV_ROS_ENV" "$log_cmd" false
      else
        make_window "10_rssi_mon" 6
        send_plain "$SESSION:10_rssi_mon.0" "$COMMON_SETUP" "$BASE_ROS_ENV" "$monitor_cmd"
        send_plain "$SESSION:10_rssi_mon.1" "$COMMON_SETUP" "$UAV_ROS_ENV" "$monitor_cmd"
        send_plain "$SESSION:10_rssi_mon.2" "$COMMON_SETUP" "$UGV_ROS_ENV" "$monitor_cmd"
        send_plain "$SESSION:10_rssi_mon.3" "$COMMON_SETUP" "$BASE_ROS_ENV" "$hz_cmd"
        send_plain "$SESSION:10_rssi_mon.4" "$COMMON_SETUP" "$BASE_ROS_ENV" "$loop_cmd"
        send_plain "$SESSION:10_rssi_mon.5" "$COMMON_SETUP" "$BASE_ROS_ENV" "$log_cmd" false
      fi
      ;;
    uav)
      make_window "10_rssi_mon" 3
      send_plain "$SESSION:10_rssi_mon.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "$monitor_cmd"
      send_plain "$SESSION:10_rssi_mon.1" "$COMMON_SETUP" "$UAV_ROS_ENV" "$hz_cmd"
      send_plain "$SESSION:10_rssi_mon.2" "$COMMON_SETUP" "$UAV_ROS_ENV" "$log_cmd" false
      ;;
    ugv)
      make_window "10_rssi_mon" 3
      send_plain "$SESSION:10_rssi_mon.0" "$COMMON_SETUP" "$UGV_ROS_ENV" "$monitor_cmd"
      send_plain "$SESSION:10_rssi_mon.1" "$COMMON_SETUP" "$UGV_ROS_ENV" "$hz_cmd"
      send_plain "$SESSION:10_rssi_mon.2" "$COMMON_SETUP" "$UGV_ROS_ENV" "$log_cmd" false
      ;;
    base)
      make_window "10_rssi_mon" 4
      send_plain "$SESSION:10_rssi_mon.0" "$COMMON_SETUP" "$BASE_ROS_ENV" "$monitor_cmd"
      send_plain "$SESSION:10_rssi_mon.1" "$COMMON_SETUP" "$BASE_ROS_ENV" "$hz_cmd"
      send_plain "$SESSION:10_rssi_mon.2" "$COMMON_SETUP" "$BASE_ROS_ENV" "$loop_cmd"
      send_plain "$SESSION:10_rssi_mon.3" "$COMMON_SETUP" "$BASE_ROS_ENV" "$log_cmd" false
      ;;
  esac
}

start_log_windows() {
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    make_window "08_logs" 4
    send_plain "$SESSION:08_logs.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "tail -F '$LOG_DIR'/*.log" false
    send_plain "$SESSION:08_logs.1" "$COMMON_SETUP" "$UAV_ROS_ENV" "watch -n 2 \"grep -R --line-number -E 'ERROR|FATAL|Traceback|Exception|Failed|Cannot transform' '$LOG_DIR' /home/nlg/.ros/log/latest 2>/dev/null | grep -vE 'roslaunch env is environ|process\\[[^]]+\\]: env' | tail -120\"" false
    send_plain "$SESSION:08_logs.2" "$COMMON_SETUP" "$UAV_ROS_ENV" "watch -n 5 roswtf"
    send_plain "$SESSION:08_logs.3" "$COMMON_SETUP" "$UGV_ROS_ENV" "watch -n 5 roswtf"
  else
    make_window "08_logs" 5
    send_plain "$SESSION:08_logs.0" "$COMMON_SETUP" "$BASE_ROS_ENV" "tail -F '$LOG_DIR'/*.log" false
    send_plain "$SESSION:08_logs.1" "$COMMON_SETUP" "$BASE_ROS_ENV" "watch -n 2 \"grep -R --line-number -E 'ERROR|FATAL|Traceback|Exception|Failed|Cannot transform' '$LOG_DIR' /home/nlg/.ros/log/latest 2>/dev/null | grep -vE 'roslaunch env is environ|process\\[[^]]+\\]: env' | tail -120\"" false
    send_plain "$SESSION:08_logs.2" "$COMMON_SETUP" "$UAV_ROS_ENV" "watch -n 5 roswtf"
    send_plain "$SESSION:08_logs.3" "$COMMON_SETUP" "$UGV_ROS_ENV" "watch -n 5 roswtf"
    send_plain "$SESSION:08_logs.4" "$COMMON_SETUP" "$BASE_ROS_ENV" "watch -n 5 roswtf"
  fi
}

start_selected_log_windows() {
  if [[ "$RUN_ONLY" == "all" ]]; then
    start_log_windows
    return
  fi

  make_window "08_logs" 3
  send_plain "$SESSION:08_logs.0" "$COMMON_SETUP" "$BASE_ROS_ENV" "tail -F '$LOG_DIR'/*.log" false
  send_plain "$SESSION:08_logs.1" "$COMMON_SETUP" "$BASE_ROS_ENV" "watch -n 2 \"grep -R --line-number -E 'ERROR|FATAL|Traceback|Exception|Failed|Cannot transform|RLException' '$LOG_DIR' /home/nlg/.ros/log/latest 2>/dev/null | grep -vE 'roslaunch env is environ|process\\[[^]]+\\]: env' | tail -120\"" false

  case "$RUN_ONLY" in
    uav) send_plain "$SESSION:08_logs.2" "$COMMON_SETUP" "$UAV_ROS_ENV" "watch -n 5 roswtf" ;;
    ugv) send_plain "$SESSION:08_logs.2" "$COMMON_SETUP" "$UGV_ROS_ENV" "watch -n 5 roswtf" ;;
    base) send_plain "$SESSION:08_logs.2" "$COMMON_SETUP" "$BASE_ROS_ENV" "watch -n 5 roswtf" ;;
  esac
}

start_manual_shells() {
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    make_window "09_manual" 3
    send_plain "$SESSION:09_manual.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "echo 'UAV shell: rostopic info /keyframe_vae; rostopic info /$UAV_FUSION_NAMESPACE/lamp/pose_graph; rosnode list; logs: $LOG_DIR'; exec bash" false
    send_plain "$SESSION:09_manual.1" "$COMMON_SETUP" "$UGV_ROS_ENV" "echo 'UGV shell: rostopic info /keyframe_vae; rostopic info /$UGV_FUSION_NAMESPACE/lamp/pose_graph; rosnode list; logs: $LOG_DIR'; exec bash" false
    send_plain "$SESSION:09_manual.2" "$COMMON_SETUP" "$UAV_ROS_ENV" "echo 'Logs: $LOG_DIR'; exec bash" false
  else
    make_window "09_manual" 4
    send_plain "$SESSION:09_manual.0" "$COMMON_SETUP" "$BASE_ROS_ENV" "echo 'Base shell: rostopic info /$UGV_MOCHA_ROBOT/keyframe_vae; rostopic echo --noarr /base1/lamp/pose_graph; rosnode info /base1/lamp'; exec bash" false
    send_plain "$SESSION:09_manual.1" "$COMMON_SETUP" "$UAV_ROS_ENV" "echo 'UAV shell: rostopic info /keyframe_vae; rosnode info /$UAV_MOCHA_ROBOT/vae_keyframe_generator'; exec bash" false
    send_plain "$SESSION:09_manual.2" "$COMMON_SETUP" "$UGV_ROS_ENV" "echo 'UGV shell: rostopic info /keyframe_vae; rosnode info /$UGV_MOCHA_ROBOT/vae_keyframe_generator'; exec bash" false
    send_plain "$SESSION:09_manual.3" "$COMMON_SETUP" "$BASE_ROS_ENV" "echo 'Logs: $LOG_DIR'; exec bash" false
  fi
}

start_selected_manual_shells() {
  if [[ "$RUN_ONLY" == "all" ]]; then
    start_manual_shells
    return
  fi

  make_window "09_manual" 1
  case "$RUN_ONLY" in
    uav) send_plain "$SESSION:09_manual.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "echo 'UAV shell: rostopic info /keyframe_vae; rosnode list; logs: $LOG_DIR'; exec bash" false ;;
    ugv) send_plain "$SESSION:09_manual.0" "$COMMON_SETUP" "$UGV_ROS_ENV" "echo 'UGV shell: rostopic info /keyframe_vae; rostopic list; rosnode list; logs: $LOG_DIR'; exec bash" false ;;
    base) send_plain "$SESSION:09_manual.0" "$COMMON_SETUP" "$BASE_ROS_ENV" "echo 'Base shell: rostopic list; rosnode list; logs: $LOG_DIR'; exec bash" false ;;
  esac
}
