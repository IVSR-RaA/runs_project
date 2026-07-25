#!/usr/bin/env bash
# lib/husky_tasks.sh
# Husky runtime tasks.

start_husky_runtime() {
  local panes=7
  if [[ "$HUSKY_ENSURE_CONTROLLER" == "true" ]]; then
    panes=$((panes + 1))
  fi
  if [[ "$HUSKY_ENABLE_CMU_PLANNER" == "true" ]]; then
    panes=$((panes + 1))
  fi
  if [[ "$HUSKY_ENABLE_YOLO" == "true" ]]; then
    panes=$((panes + 1))
  fi
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    panes=$((panes + 3))
  fi

  make_window "03_husky_run" "$panes"
  send_plain "$SESSION:03_husky_run.0" "$COMMON_SETUP" "$HUSKY_ROS_ENV" "echo '[delay] Husky group starts in $HUSKY_START_DELAY seconds'; sleep '$HUSKY_START_DELAY' && roscore -p 11314" false
  send_plain "$SESSION:03_husky_run.1" "$COMMON_SETUP" "$HUSKY_ROS_ENV" "roslaunch gazebo_ros empty_world.launch world_name:='$SIM_WORLD_FILE' gui:=false paused:=false use_sim_time:=true"
  send_plain "$SESSION:03_husky_run.2" "$COMMON_SETUP" "$HUSKY_ROS_ENV" "$WAIT_FOR_GAZEBO; sleep $HUSKY_SPAWN_DELAY; $HUSKY_CAMERA_ENV ROBOT_SIMULATION=true HUSKY_LASER_3D_ENABLED=1 HUSKY_LASER_3D_TOPIC=points HUSKY_LASER_3D_XYZ='0 0 $HUSKY_LIDAR_Z_OFFSET' roslaunch mocha_launch husky.launch $MOCHA_ROBOT_CONFIG_ARG robot_name:=$HUSKY_MOCHA_ROBOT joystick:=false x:=$HUSKY_SPAWN_X y:=$HUSKY_SPAWN_Y z:=$HUSKY_SPAWN_Z yaw:=$HUSKY_SPAWN_YAW"
  send_plain "$SESSION:03_husky_run.3" "$COMMON_SETUP" "$HUSKY_ROS_ENV" "$WAIT_FOR_HUSKY_SENSORS; roslaunch super_lio velodyne_16.launch config_file:='$HUSKY_LIO_CONFIG_FILE' lidar_topic:=$HUSKY_LIDAR_TOPIC imu_topic:=$HUSKY_IMU_TOPIC rviz:=false"
  send_plain "$SESSION:03_husky_run.4" "$COMMON_SETUP" "$HUSKY_ROS_ENV" "roslaunch super_lio_lamp_adapter robot_tf.launch robot_name:=$HUSKY_LAMP_ROBOT odom_topic:=$HUSKY_ODOM_TOPIC world_to_map_x:=$HUSKY_MAP_X world_to_map_y:=$HUSKY_MAP_Y world_to_map_z:=$HUSKY_MAP_Z stamp_odom_tf_with_now:=true"
  send_plain "$SESSION:03_husky_run.5" "$VAE_SETUP" "$HUSKY_ROS_ENV" "$WAIT_FOR_HUSKY_LIO_OUTPUTS; roslaunch super_lio_lamp_adapter local_vae_keyframe_pipeline.launch robot_namespace:=$HUSKY_MOCHA_ROBOT robot_id:=$HUSKY_MOCHA_ROBOT robot_type:=$HUSKY_VAE_ROBOT_TYPE point_cloud_topic:=$HUSKY_VAE_POINT_TOPIC odom_topic:=$HUSKY_ODOM_TOPIC keyframe_vae_topic:=/keyframe_vae"
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    send_plain "$SESSION:03_husky_run.6" "$VAE_SETUP" "$HUSKY_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$HUSKY_MOCHA_ROBOT source_robot_id:=$HUSKY_MOCHA_ROBOT lamp_robot_namespace:=$HUSKY_LAMP_ROBOT robot_prefix:=$HUSKY_LAMP_PREFIX robot_type:=$HUSKY_VAE_ROBOT_TYPE keyframe_vae_topic:=/$HUSKY_MOCHA_ROBOT/keyframe_vae target_frame:=$WORLD_FRAME sensor_frame:=$HUSKY_LIDAR_FRAME output_namespace:=$HUSKY_LAMP_ROBOT/reconstructed_local"
  else
    send_plain "$SESSION:03_husky_run.6" "$COMMON_SETUP" "$HUSKY_ROS_ENV" "$WAIT_FOR_HUSKY_LIO_OUTPUTS; roslaunch super_lio_lamp_adapter local_lio_to_lamp.launch robot_namespace:=$HUSKY_LAMP_ROBOT robot_id:=$HUSKY_MOCHA_ROBOT robot_prefix:=$HUSKY_LAMP_PREFIX odom_topic:=$HUSKY_ODOM_TOPIC cloud_topic:=$HUSKY_CLOUD_BODY_TOPIC fixed_frame_id:=$WORLD_FRAME"
  fi

  local next_pane=7
  if [[ "$HUSKY_ENSURE_CONTROLLER" == "true" ]]; then
    send_plain "$SESSION:03_husky_run.$next_pane" "$COMMON_SETUP" "$HUSKY_ROS_ENV" "python3 '$WS/src/mrm_run_launch/scripts/ensure_ros_controller_running.py' --controller '$HUSKY_CONTROLLER_NAME' --controller-manager-namespace '$HUSKY_CONTROLLER_MANAGER_NAMESPACE' --model '$HUSKY_GAZEBO_MODEL_NAME' --timeout '$HUSKY_CONTROLLER_TIMEOUT'"
    next_pane=$((next_pane + 1))
  fi
  if [[ "$HUSKY_ENABLE_YOLO" == "true" ]]; then
    send_plain "$SESSION:03_husky_run.$next_pane" "$YOLO_SETUP" "$HUSKY_ROS_ENV" "$WAIT_FOR_HUSKY_CAMERA; roslaunch mrm_yolo yolov8_detector.launch robot_name:=$HUSKY_MOCHA_ROBOT image_topic:=$HUSKY_YOLO_IMAGE_TOPIC odom_topic:=$HUSKY_ODOM_TOPIC model:='$YOLO_MODEL' device:=$YOLO_DEVICE conf_threshold:=$YOLO_CONFIDENCE max_rate:=$YOLO_MAX_RATE enable_tracking:=$YOLO_ENABLE_TRACKING tracker:=$YOLO_TRACKER trajectory_length:=$YOLO_TRAJECTORY_LENGTH publish_annotated:=$YOLO_PUBLISH_ANNOTATED fixed_depth_m:=$YOLO_FIXED_DEPTH_M"
    next_pane=$((next_pane + 1))
  fi
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    send_plain "$SESSION:03_husky_run.$next_pane" "$VAE_SETUP" "$HUSKY_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$UAV_MOCHA_ROBOT source_robot_id:=$UAV_MOCHA_ROBOT lamp_robot_namespace:=$UAV_LAMP_ROBOT robot_prefix:=$UAV_LAMP_PREFIX robot_type:=$UAV_VAE_ROBOT_TYPE target_frame:=$WORLD_FRAME sensor_frame:=$UAV_LIDAR_FRAME output_namespace:=$UAV_LAMP_ROBOT/reconstructed"
    next_pane=$((next_pane + 1))
    send_plain "$SESSION:03_husky_run.$next_pane" "$VAE_SETUP" "$HUSKY_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$UGV_MOCHA_ROBOT source_robot_id:=$UGV_MOCHA_ROBOT lamp_robot_namespace:=$UGV_LAMP_ROBOT robot_prefix:=$UGV_LAMP_PREFIX robot_type:=$UGV_VAE_ROBOT_TYPE target_frame:=$WORLD_FRAME sensor_frame:=$UGV_LIDAR_FRAME output_namespace:=$UGV_LAMP_ROBOT/reconstructed"
    next_pane=$((next_pane + 1))

    local base1_relays
    base1_relays="$(distributed_base1_compat_relays "$HUSKY_FUSION_NAMESPACE" "husky_fusion")"
    send_plain "$SESSION:03_husky_run.$next_pane" "$COMMON_SETUP" "$HUSKY_ROS_ENV" "rosparam load '$BASE_LAMP_ROBOT_NAMES_CONFIG' /base1/lamp; $base1_relays roslaunch lamp turn_on_lamp_base.launch robot_namespace:=$HUSKY_FUSION_NAMESPACE robot_names_config:='$BASE_LAMP_ROBOT_NAMES_CONFIG' rssi_parameters_config:='$BASE_RSSI_PARAMETERS_CONFIG' run_loop_closure_batcher:=$RUN_GNN_BATCHER $LAMP_SOLID_ARGS"
    next_pane=$((next_pane + 1))
  fi

  if [[ "$HUSKY_ENABLE_CMU_PLANNER" == "true" ]]; then
    local planner_cmd
    planner_cmd="$WAIT_FOR_HUSKY_CMU_INPUTS; roslaunch mrm_run_launch ugv_cmu_planner.launch state_estimation_topic:=$HUSKY_CMU_STATE_TOPIC registered_scan_topic:=$HUSKY_CMU_SCAN_TOPIC cmd_vel_topic:=$HUSKY_CMU_CMD_VEL_TOPIC cmd_vel_stamped_topic:=$HUSKY_CMU_CMD_VEL_STAMPED_TOPIC run_waypoint_example:=$HUSKY_CMU_RUN_WAYPOINTS planner_max_speed:=$HUSKY_CMU_MAX_SPEED planner_autonomy_speed:=$HUSKY_CMU_AUTONOMY_SPEED planner_vehicle_length:=$HUSKY_CMU_VEHICLE_LENGTH planner_vehicle_width:=$HUSKY_CMU_VEHICLE_WIDTH planner_check_rot_obstacle:=$HUSKY_CMU_CHECK_ROT_OBSTACLE planner_path_scale:=$HUSKY_CMU_PATH_SCALE planner_min_path_scale:=$HUSKY_CMU_MIN_PATH_SCALE planner_path_scale_by_speed:=$HUSKY_CMU_PATH_SCALE_BY_SPEED waypoint_speed:=$HUSKY_CMU_WAYPOINT_SPEED waypoint_xy_radius:=$HUSKY_CMU_WAYPOINT_RADIUS waypoint_z_bound:=$HUSKY_CMU_WAYPOINT_Z_BOUND waypoint_wait_time:=$HUSKY_CMU_WAYPOINT_WAIT run_mission_monitor:=$HUSKY_CMU_RUN_MONITOR mission_monitor_label:=$HUSKY_MOCHA_ROBOT mission_monitor_status_period:=$CMU_MISSION_MONITOR_STATUS_PERIOD mission_monitor_stale_timeout:=$CMU_MISSION_MONITOR_STALE_TIMEOUT mission_monitor_progress_timeout:=$CMU_MISSION_MONITOR_PROGRESS_TIMEOUT"
    if [[ -n "$HUSKY_CMU_WAYPOINT_FILE" ]]; then
      planner_cmd+=" waypoint_file_dir:='$HUSKY_CMU_WAYPOINT_FILE'"
    fi
    if [[ -n "$HUSKY_CMU_BOUNDARY_FILE" ]]; then
      planner_cmd+=" boundary_file_dir:='$HUSKY_CMU_BOUNDARY_FILE'"
    fi
    send_plain "$SESSION:03_husky_run.$next_pane" "$COMMON_SETUP" "$HUSKY_ROS_ENV" "$planner_cmd"
  fi
}
