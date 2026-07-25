#!/usr/bin/env bash
# lib/ugv_tasks.sh
# UGV runtime tasks.

start_ugv_runtime() {
  local panes=8
  if [[ "$UGV_ENSURE_JACKAL_CONTROLLER" == "true" ]]; then
    panes=$((panes + 1))
  fi
  if [[ "$UGV_ENABLE_CMU_PLANNER" == "true" ]]; then
    panes=$((panes + 1))
  fi
  if [[ "$UGV_ENABLE_YOLO" == "true" ]]; then
    panes=$((panes + 1))
  fi
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    panes=$((panes + 3))
  fi

  make_window "02_ugv_run" "$panes"
  send_plain "$SESSION:02_ugv_run.0" "$COMMON_SETUP" "$UGV_ROS_ENV" "echo '[delay] UGV group starts in $UGV_START_DELAY seconds'; sleep '$UGV_START_DELAY' && roscore -p 11312" false
  send_plain "$SESSION:02_ugv_run.1" "$COMMON_SETUP" "$UGV_ROS_ENV" "roslaunch gazebo_ros empty_world.launch world_name:='$SIM_WORLD_FILE' gui:=false paused:=false use_sim_time:=true"
  send_plain "$SESSION:02_ugv_run.2" "$COMMON_SETUP" "$UGV_ROS_ENV" "$WAIT_FOR_GAZEBO; sleep $UGV_SPAWN_DELAY; $UGV_CAMERA_ENV JACKAL_LASER_3D=1 JACKAL_LASER_3D_OFFSET='0 0 $UGV_LIDAR_Z_OFFSET' roslaunch mocha_launch jackal.launch $MOCHA_ROBOT_CONFIG_ARG robot_name:=$UGV_MOCHA_ROBOT joystick:=false x:=$UGV_SPAWN_X y:=$UGV_SPAWN_Y z:=$UGV_SPAWN_Z yaw:=$UGV_SPAWN_YAW"
  send_plain "$SESSION:02_ugv_run.3" "$COMMON_SETUP" "$UGV_ROS_ENV" "$WAIT_FOR_UGV_SENSORS; roslaunch super_lio velodyne_16.launch config_file:='$UGV_LIO_CONFIG_FILE' lidar_topic:=$UGV_LIDAR_TOPIC imu_topic:=$UGV_IMU_TOPIC rviz:=false"
  send_plain "$SESSION:02_ugv_run.4" "$COMMON_SETUP" "$UGV_ROS_ENV" "roslaunch super_lio_lamp_adapter robot_tf.launch robot_name:=$UGV_LAMP_ROBOT odom_topic:=$UGV_ODOM_TOPIC world_to_map_x:=$UGV_MAP_X world_to_map_y:=$UGV_MAP_Y world_to_map_z:=$UGV_MAP_Z stamp_odom_tf_with_now:=true"
  send_plain "$SESSION:02_ugv_run.5" "$VAE_SETUP" "$UGV_ROS_ENV" "$WAIT_FOR_UGV_LIO_OUTPUTS; roslaunch super_lio_lamp_adapter local_vae_keyframe_pipeline.launch robot_namespace:=$UGV_MOCHA_ROBOT robot_id:=$UGV_MOCHA_ROBOT robot_type:=$UGV_VAE_ROBOT_TYPE point_cloud_topic:=$UGV_VAE_POINT_TOPIC odom_topic:=$UGV_ODOM_TOPIC keyframe_vae_topic:=/keyframe_vae"
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    send_plain "$SESSION:02_ugv_run.6" "$VAE_SETUP" "$UGV_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$UGV_MOCHA_ROBOT source_robot_id:=$UGV_MOCHA_ROBOT lamp_robot_namespace:=$UGV_LAMP_ROBOT robot_prefix:=$UGV_LAMP_PREFIX robot_type:=$UGV_VAE_ROBOT_TYPE keyframe_vae_topic:=/$UGV_MOCHA_ROBOT/keyframe_vae target_frame:=$WORLD_FRAME sensor_frame:=$UGV_LIDAR_FRAME output_namespace:=$UGV_LAMP_ROBOT/reconstructed_local"
  else
  send_plain "$SESSION:02_ugv_run.6" "$COMMON_SETUP" "$UGV_ROS_ENV" "$WAIT_FOR_UGV_LIO_OUTPUTS; roslaunch super_lio_lamp_adapter local_lio_to_lamp.launch robot_namespace:=$UGV_LAMP_ROBOT robot_id:=$UGV_MOCHA_ROBOT robot_prefix:=$UGV_LAMP_PREFIX odom_topic:=$UGV_ODOM_TOPIC cloud_topic:=$UGV_CLOUD_BODY_TOPIC fixed_frame_id:=$WORLD_FRAME"
  fi
  send_plain "$SESSION:02_ugv_run.7" "$COMMON_SETUP" "$UGV_ROS_ENV" "rosrun tf2_ros static_transform_publisher 0 0 0 0 0 0 1 base_link jackal_base_link"

  local next_pane=8
  if [[ "$UGV_ENSURE_JACKAL_CONTROLLER" == "true" ]]; then
    send_plain "$SESSION:02_ugv_run.$next_pane" "$COMMON_SETUP" "$UGV_ROS_ENV" "python3 '$WS/src/mrm_run_launch/scripts/ensure_ros_controller_running.py' --controller '$UGV_JACKAL_CONTROLLER_NAME' --model '$UGV_GAZEBO_MODEL_NAME' --timeout '$UGV_JACKAL_CONTROLLER_TIMEOUT'"
    next_pane=$((next_pane + 1))
  fi
  if [[ "$UGV_ENABLE_YOLO" == "true" ]]; then
    send_plain "$SESSION:02_ugv_run.$next_pane" "$YOLO_SETUP" "$UGV_ROS_ENV" "$WAIT_FOR_UGV_CAMERA; roslaunch mrm_yolo yolov8_detector.launch robot_name:=$UGV_MOCHA_ROBOT image_topic:=$UGV_YOLO_IMAGE_TOPIC odom_topic:=$UGV_ODOM_TOPIC model:='$YOLO_MODEL' device:=$YOLO_DEVICE conf_threshold:=$YOLO_CONFIDENCE max_rate:=$YOLO_MAX_RATE enable_tracking:=$YOLO_ENABLE_TRACKING tracker:=$YOLO_TRACKER trajectory_length:=$YOLO_TRAJECTORY_LENGTH publish_annotated:=$YOLO_PUBLISH_ANNOTATED fixed_depth_m:=$YOLO_FIXED_DEPTH_M"
    next_pane=$((next_pane + 1))
  fi
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    send_plain "$SESSION:02_ugv_run.$next_pane" "$VAE_SETUP" "$UGV_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$UAV_MOCHA_ROBOT source_robot_id:=$UAV_MOCHA_ROBOT lamp_robot_namespace:=$UAV_LAMP_ROBOT robot_prefix:=$UAV_LAMP_PREFIX robot_type:=$UAV_VAE_ROBOT_TYPE target_frame:=$WORLD_FRAME sensor_frame:=$UAV_LIDAR_FRAME output_namespace:=$UAV_LAMP_ROBOT/reconstructed"
    next_pane=$((next_pane + 1))
    send_plain "$SESSION:02_ugv_run.$next_pane" "$VAE_SETUP" "$UGV_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$HUSKY_MOCHA_ROBOT source_robot_id:=$HUSKY_MOCHA_ROBOT lamp_robot_namespace:=$HUSKY_LAMP_ROBOT robot_prefix:=$HUSKY_LAMP_PREFIX robot_type:=$HUSKY_VAE_ROBOT_TYPE target_frame:=$WORLD_FRAME sensor_frame:=$HUSKY_LIDAR_FRAME output_namespace:=$HUSKY_LAMP_ROBOT/reconstructed"
    next_pane=$((next_pane + 1))
  fi
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    local base1_relays
    base1_relays="$(distributed_base1_compat_relays "$UGV_FUSION_NAMESPACE" "ugv_fusion")"
    send_plain "$SESSION:02_ugv_run.$next_pane" "$COMMON_SETUP" "$UGV_ROS_ENV" "rosparam load '$BASE_LAMP_ROBOT_NAMES_CONFIG' /base1/lamp; $base1_relays roslaunch lamp turn_on_lamp_base.launch robot_namespace:=$UGV_FUSION_NAMESPACE robot_names_config:='$BASE_LAMP_ROBOT_NAMES_CONFIG' rssi_parameters_config:='$BASE_RSSI_PARAMETERS_CONFIG' run_loop_closure_batcher:=$RUN_GNN_BATCHER $LAMP_SOLID_ARGS"
    next_pane=$((next_pane + 1))
  fi
  if [[ "$UGV_ENABLE_CMU_PLANNER" == "true" ]]; then
    local planner_cmd
    planner_cmd="$WAIT_FOR_UGV_CMU_INPUTS; roslaunch mrm_run_launch ugv_cmu_planner.launch state_estimation_topic:=$UGV_CMU_STATE_TOPIC registered_scan_topic:=$UGV_CMU_SCAN_TOPIC cmd_vel_topic:=$UGV_CMU_CMD_VEL_TOPIC cmd_vel_stamped_topic:=$UGV_CMU_CMD_VEL_STAMPED_TOPIC run_waypoint_example:=$UGV_CMU_RUN_WAYPOINTS planner_max_speed:=$UGV_CMU_MAX_SPEED planner_autonomy_speed:=$UGV_CMU_AUTONOMY_SPEED planner_vehicle_length:=$UGV_CMU_VEHICLE_LENGTH planner_vehicle_width:=$UGV_CMU_VEHICLE_WIDTH planner_check_rot_obstacle:=$UGV_CMU_CHECK_ROT_OBSTACLE planner_path_scale:=$UGV_CMU_PATH_SCALE planner_min_path_scale:=$UGV_CMU_MIN_PATH_SCALE planner_path_scale_by_speed:=$UGV_CMU_PATH_SCALE_BY_SPEED waypoint_speed:=$UGV_CMU_WAYPOINT_SPEED waypoint_xy_radius:=$UGV_CMU_WAYPOINT_RADIUS waypoint_z_bound:=$UGV_CMU_WAYPOINT_Z_BOUND waypoint_wait_time:=$UGV_CMU_WAYPOINT_WAIT run_mission_monitor:=$UGV_CMU_RUN_MONITOR mission_monitor_label:=$UGV_MOCHA_ROBOT mission_monitor_status_period:=$CMU_MISSION_MONITOR_STATUS_PERIOD mission_monitor_stale_timeout:=$CMU_MISSION_MONITOR_STALE_TIMEOUT mission_monitor_progress_timeout:=$CMU_MISSION_MONITOR_PROGRESS_TIMEOUT"
    if [[ -n "$UGV_CMU_WAYPOINT_FILE" ]]; then
      planner_cmd+=" waypoint_file_dir:='$UGV_CMU_WAYPOINT_FILE'"
    fi
    if [[ -n "$UGV_CMU_BOUNDARY_FILE" ]]; then
      planner_cmd+=" boundary_file_dir:='$UGV_CMU_BOUNDARY_FILE'"
    fi
    send_plain "$SESSION:02_ugv_run.$next_pane" "$COMMON_SETUP" "$UGV_ROS_ENV" "$planner_cmd"
  fi
}
