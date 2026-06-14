#!/usr/bin/env bash
# lib/uav_tasks.sh
# UAV runtime tasks.

# shellcheck source=/home/nlg/all_ws/run/lib/tmux_utils.sh
source "$SCRIPT_DIR/lib/tmux_utils.sh"

start_uav_runtime() {
  local mission_use_position_setpoints="$UAV_SEQUENCE_USE_POSITION_SETPOINTS"
  if [[ "$UAV_ENABLE_EGO_PLANNER" == "true" ]]; then
    mission_use_position_setpoints="$UAV_EGO_USE_POSITION_SETPOINTS"
  fi

  local panes=6
  if [[ "$UAV_ENABLE_SEQUENCE_CONTROLLER" == "true" ]]; then
    panes=$((panes + 1))
  fi
  if [[ "$UAV_ENABLE_YOLO" == "true" ]]; then
    panes=$((panes + 1))
  fi
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    panes=$((panes + 3))
  fi
  local next_pane=6

  make_window "01_uav_run" "$panes"
  send_plain "$SESSION:01_uav_run.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "echo '[delay] UAV group starts in $UAV_START_DELAY seconds'; sleep '$UAV_START_DELAY' && roscore -p 11313" false
  send_plain "$SESSION:01_uav_run.1" "$COMMON_SETUP" "$UAV_ROS_ENV" "test -f '$PX4_UAV_SDF' && roslaunch mrm_run_launch uav_sim_mocha.launch robot_name:=$UAV_MOCHA_ROBOT $MOCHA_ROBOT_CONFIG_ARG sdf:='$PX4_UAV_SDF' world:='$SIM_WORLD_FILE' gui:=true x:=$UAV_SPAWN_X y:=$UAV_SPAWN_Y z:=$UAV_SPAWN_Z R:=$UAV_SPAWN_ROLL P:=$UAV_SPAWN_PITCH Y:=$UAV_SPAWN_YAW enable_camera:=$UAV_ENABLE_CAMERA"
  send_plain "$SESSION:01_uav_run.2" "$COMMON_SETUP" "$UAV_ROS_ENV" "$WAIT_FOR_UAV_SENSORS; roslaunch super_lio velodyne_16.launch lidar_topic:=$UAV_LIDAR_TOPIC imu_topic:=$UAV_IMU_TOPIC rviz:=false"
  send_plain "$SESSION:01_uav_run.3" "$COMMON_SETUP" "$UAV_ROS_ENV" "roslaunch super_lio_lamp_adapter robot_tf.launch robot_name:=$UAV_LAMP_ROBOT odom_topic:=$UAV_ODOM_TOPIC world_to_map_x:=$UAV_MAP_X world_to_map_y:=$UAV_MAP_Y world_to_map_z:=$UAV_MAP_Z"
  send_plain "$SESSION:01_uav_run.4" "$VAE_SETUP" "$UAV_ROS_ENV" "$WAIT_FOR_UAV_LIO_OUTPUTS; roslaunch super_lio_lamp_adapter local_vae_keyframe_pipeline.launch robot_namespace:=$UAV_MOCHA_ROBOT robot_id:=$UAV_MOCHA_ROBOT robot_type:=$UAV_VAE_ROBOT_TYPE point_cloud_topic:=$UAV_VAE_POINT_TOPIC odom_topic:=$UAV_ODOM_TOPIC keyframe_vae_topic:=/keyframe_vae"
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    send_plain "$SESSION:01_uav_run.5" "$VAE_SETUP" "$UAV_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$UAV_MOCHA_ROBOT source_robot_id:=$UAV_MOCHA_ROBOT lamp_robot_namespace:=$UAV_LAMP_ROBOT robot_prefix:=$UAV_LAMP_PREFIX robot_type:=$UAV_VAE_ROBOT_TYPE keyframe_vae_topic:=/$UAV_MOCHA_ROBOT/keyframe_vae target_frame:=$WORLD_FRAME sensor_frame:=$UAV_LIDAR_FRAME output_namespace:=$UAV_LAMP_ROBOT/reconstructed_local"
  else
    send_plain "$SESSION:01_uav_run.5" "$COMMON_SETUP" "$UAV_ROS_ENV" "$WAIT_FOR_UAV_LIO_OUTPUTS; roslaunch super_lio_lamp_adapter local_lio_to_lamp.launch robot_namespace:=$UAV_LAMP_ROBOT robot_id:=$UAV_MOCHA_ROBOT robot_prefix:=$UAV_LAMP_PREFIX odom_topic:=$UAV_ODOM_TOPIC cloud_topic:=$UAV_CLOUD_BODY_TOPIC fixed_frame_id:=$WORLD_FRAME"
  fi
  if [[ "$UAV_ENABLE_YOLO" == "true" ]]; then
    send_plain "$SESSION:01_uav_run.$next_pane" "$YOLO_SETUP" "$UAV_ROS_ENV" "$WAIT_FOR_UAV_CAMERA; roslaunch mrm_yolo yolov8_detector.launch robot_name:=$UAV_MOCHA_ROBOT image_topic:=$UAV_YOLO_IMAGE_TOPIC odom_topic:=$UAV_ODOM_TOPIC model:='$YOLO_MODEL' device:=$YOLO_DEVICE conf_threshold:=$YOLO_CONFIDENCE max_rate:=$YOLO_MAX_RATE enable_tracking:=$YOLO_ENABLE_TRACKING tracker:=$YOLO_TRACKER trajectory_length:=$YOLO_TRAJECTORY_LENGTH publish_annotated:=$YOLO_PUBLISH_ANNOTATED fixed_depth_m:=$YOLO_FIXED_DEPTH_M"
    next_pane=$((next_pane + 1))
  fi
  if [[ "$UAV_ENABLE_SEQUENCE_CONTROLLER" == "true" ]]; then
    send_plain "$SESSION:01_uav_run.$next_pane" "$COMMON_SETUP" "$UAV_ROS_ENV" "roslaunch mrm_run_launch uav_sequence_controller.launch sequence_yaml:='$UAV_SEQUENCE_YAML' run_geometric_controller:=$UAV_SEQUENCE_RUN_GEOMETRIC_CONTROLLER run_sequence_parser:=$UAV_SEQUENCE_RUN_PARSER run_local_sequence_server:=$UAV_SEQUENCE_RUN_LOCAL_SERVER run_gps_sequence_server:=$UAV_SEQUENCE_RUN_GPS_SERVER run_external_scripts:=$UAV_SEQUENCE_RUN_EXTERNAL_SCRIPTS run_ego_planner:=$UAV_ENABLE_EGO_PLANNER mission_use_position_setpoints:=$mission_use_position_setpoints mav_name:=$UAV_SEQUENCE_MAV_NAME ego_odom_topic:=$UAV_EGO_ODOM_TOPIC ego_cloud_topic:=$UAV_EGO_CLOUD_TOPIC ego_use_raw_cloud_adapter:=$UAV_EGO_USE_RAW_CLOUD_ADAPTER ego_raw_cloud_topic:=$UAV_EGO_RAW_CLOUD_TOPIC ego_cloud_target_frame:=$UAV_EGO_CLOUD_TARGET_FRAME ego_cloud_minimum_range:=$UAV_EGO_CLOUD_MINIMUM_RANGE ego_map_size_x:=$UAV_EGO_MAP_SIZE_X ego_map_size_y:=$UAV_EGO_MAP_SIZE_Y ego_map_size_z:=$UAV_EGO_MAP_SIZE_Z ego_max_velocity:=$UAV_EGO_MAX_VELOCITY ego_max_acceleration:=$UAV_EGO_MAX_ACCELERATION ego_planning_horizon:=$UAV_EGO_PLANNING_HORIZON ego_obstacle_inflation:=$UAV_EGO_OBSTACLE_INFLATION ego_obstacle_inflation_z:=$UAV_EGO_OBSTACLE_INFLATION_Z ego_lambda_fitness:=$UAV_EGO_LAMBDA_FITNESS ego_spawn_test_obstacle:=$UAV_EGO_SPAWN_TEST_OBSTACLE"
    next_pane=$((next_pane + 1))
  fi
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    send_plain "$SESSION:01_uav_run.$next_pane" "$VAE_SETUP" "$UAV_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$UGV_MOCHA_ROBOT source_robot_id:=$UGV_MOCHA_ROBOT lamp_robot_namespace:=$UGV_LAMP_ROBOT robot_prefix:=$UGV_LAMP_PREFIX robot_type:=$UGV_VAE_ROBOT_TYPE target_frame:=$WORLD_FRAME sensor_frame:=$UGV_LIDAR_FRAME output_namespace:=$UGV_LAMP_ROBOT/reconstructed"
    next_pane=$((next_pane + 1))
    send_plain "$SESSION:01_uav_run.$next_pane" "$VAE_SETUP" "$UAV_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$HUSKY_MOCHA_ROBOT source_robot_id:=$HUSKY_MOCHA_ROBOT lamp_robot_namespace:=$HUSKY_LAMP_ROBOT robot_prefix:=$HUSKY_LAMP_PREFIX robot_type:=$HUSKY_VAE_ROBOT_TYPE target_frame:=$WORLD_FRAME sensor_frame:=$HUSKY_LIDAR_FRAME output_namespace:=$HUSKY_LAMP_ROBOT/reconstructed"
    next_pane=$((next_pane + 1))
  fi
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    local base1_relays
    base1_relays="$(distributed_base1_compat_relays "$UAV_FUSION_NAMESPACE" "uav_fusion")"
    send_plain "$SESSION:01_uav_run.$next_pane" "$COMMON_SETUP" "$UAV_ROS_ENV" "rosparam load '$BASE_LAMP_ROBOT_NAMES_CONFIG' /base1/lamp; $base1_relays roslaunch lamp turn_on_lamp_base.launch robot_namespace:=$UAV_FUSION_NAMESPACE robot_names_config:='$BASE_LAMP_ROBOT_NAMES_CONFIG' rssi_parameters_config:='$BASE_RSSI_PARAMETERS_CONFIG' run_loop_closure_batcher:=$RUN_GNN_BATCHER $LAMP_SOLID_ARGS"
  fi
}
