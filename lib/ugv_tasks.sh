#!/usr/bin/env bash
# lib/ugv_tasks.sh
# UGV runtime tasks.

start_ugv_runtime() {
  local panes=8
  if [[ "$RUN_ONLY" == "all" ]]; then
    panes=9
  fi
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    panes=$((panes + 1))
  fi

  make_window "02_ugv_run" "$panes"
  send_plain "$SESSION:02_ugv_run.0" "$COMMON_SETUP" "$UGV_ROS_ENV" "roscore -p 11312" false
  send_plain "$SESSION:02_ugv_run.1" "$COMMON_SETUP" "$UGV_ROS_ENV" "roslaunch gazebo_ros empty_world.launch world_name:='$SIM_WORLD_FILE' gui:=false paused:=false use_sim_time:=true"
  send_plain "$SESSION:02_ugv_run.2" "$COMMON_SETUP" "$UGV_ROS_ENV" "$WAIT_FOR_GAZEBO; sleep $UGV_SPAWN_DELAY; JACKAL_LASER_3D=1 roslaunch mocha_launch jackal.launch $MOCHA_ROBOT_CONFIG_ARG joystick:=false x:=$UGV_SPAWN_X y:=$UGV_SPAWN_Y z:=$UGV_SPAWN_Z yaw:=$UGV_SPAWN_YAW"
  send_plain "$SESSION:02_ugv_run.3" "$COMMON_SETUP" "$UGV_ROS_ENV" "$WAIT_FOR_UGV_SENSORS; roslaunch super_lio velodyne_16.launch lidar_topic:=$UGV_LIDAR_TOPIC imu_topic:=$UGV_IMU_TOPIC rviz:=false"
  send_plain "$SESSION:02_ugv_run.4" "$COMMON_SETUP" "$UGV_ROS_ENV" "roslaunch super_lio_lamp_adapter robot_tf.launch robot_name:=$UGV_LAMP_ROBOT odom_topic:=$UGV_ODOM_TOPIC world_to_map_x:=$UGV_MAP_X world_to_map_y:=$UGV_MAP_Y world_to_map_z:=$UGV_MAP_Z stamp_odom_tf_with_now:=true"
  send_plain "$SESSION:02_ugv_run.5" "$VAE_SETUP" "$UGV_ROS_ENV" "$WAIT_FOR_UGV_LIO_OUTPUTS; roslaunch super_lio_lamp_adapter local_vae_keyframe_pipeline.launch robot_namespace:=$UGV_MOCHA_ROBOT robot_id:=$UGV_MOCHA_ROBOT robot_type:=ground point_cloud_topic:=$UGV_VAE_POINT_TOPIC odom_topic:=$UGV_ODOM_TOPIC keyframe_vae_topic:=/keyframe_vae"
  send_plain "$SESSION:02_ugv_run.6" "$COMMON_SETUP" "$UGV_ROS_ENV" "$WAIT_FOR_UGV_LIO_OUTPUTS; roslaunch super_lio_lamp_adapter local_lio_to_lamp.launch robot_namespace:=$UGV_LAMP_ROBOT robot_id:=$UGV_MOCHA_ROBOT robot_prefix:=$UGV_LAMP_PREFIX odom_topic:=$UGV_ODOM_TOPIC cloud_topic:=$UGV_CLOUD_BODY_TOPIC fixed_frame_id:=$WORLD_FRAME"
  send_plain "$SESSION:02_ugv_run.7" "$COMMON_SETUP" "$UGV_ROS_ENV" "rosrun tf2_ros static_transform_publisher 0 0 0 0 0 0 1 base_link jackal_base_link"
  if [[ "$RUN_ONLY" == "all" ]]; then
    send_plain "$SESSION:02_ugv_run.8" "$VAE_SETUP" "$UGV_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$UAV_MOCHA_ROBOT source_robot_id:=$UAV_MOCHA_ROBOT lamp_robot_namespace:=$UAV_LAMP_ROBOT robot_prefix:=$UAV_LAMP_PREFIX robot_type:=aerial target_frame:=$WORLD_FRAME sensor_frame:=$UAV_LIDAR_FRAME output_namespace:=$UAV_LAMP_ROBOT/reconstructed"
  fi
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    local fusion_pane=8
    local base1_relays
    if [[ "$RUN_ONLY" == "all" ]]; then
      fusion_pane=9
    fi
    base1_relays="$(distributed_base1_compat_relays "$UGV_FUSION_NAMESPACE" "ugv_fusion")"
    send_plain "$SESSION:02_ugv_run.$fusion_pane" "$COMMON_SETUP" "$UGV_ROS_ENV" "rosparam load '$BASE_LAMP_ROBOT_NAMES_CONFIG' /base1/lamp; $base1_relays roslaunch lamp turn_on_lamp_base.launch robot_namespace:=$UGV_FUSION_NAMESPACE robot_names_config:='$BASE_LAMP_ROBOT_NAMES_CONFIG' rssi_parameters_config:='$BASE_RSSI_PARAMETERS_CONFIG' run_loop_closure_batcher:=$RUN_GNN_BATCHER"
  fi
}
