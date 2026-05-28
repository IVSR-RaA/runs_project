#!/usr/bin/env bash
# lib/base_tasks.sh
# Base station runtime tasks.

start_base_runtime() {
  make_window "03_base_run" 6
  send_plain "$SESSION:03_base_run.0" "$COMMON_SETUP" "$BASE_ROS_ENV" "roscore -p 11311" false
  send_plain "$SESSION:03_base_run.1" "$COMMON_SETUP" "$BASE_ROS_ENV" "roslaunch mocha_launch basestation.launch $MOCHA_ROBOT_CONFIG_ARG"
  send_plain "$SESSION:03_base_run.2" "$COMMON_SETUP" "$BASE_ROS_ENV" "roslaunch lamp turn_on_lamp_base.launch robot_namespace:=base1 robot_names_config:='$BASE_LAMP_ROBOT_NAMES_CONFIG' rssi_parameters_config:='$BASE_RSSI_PARAMETERS_CONFIG' run_loop_closure_batcher:=$RUN_GNN_BATCHER"
  send_plain "$SESSION:03_base_run.3" "$VAE_SETUP" "$BASE_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$UAV_MOCHA_ROBOT source_robot_id:=$UAV_MOCHA_ROBOT lamp_robot_namespace:=$UAV_LAMP_ROBOT robot_prefix:=$UAV_LAMP_PREFIX robot_type:=$UAV_VAE_ROBOT_TYPE target_frame:=$WORLD_FRAME sensor_frame:=$UAV_LIDAR_FRAME output_namespace:=$UAV_LAMP_ROBOT/reconstructed"
  send_plain "$SESSION:03_base_run.4" "$VAE_SETUP" "$BASE_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$UGV_MOCHA_ROBOT source_robot_id:=$UGV_MOCHA_ROBOT lamp_robot_namespace:=$UGV_LAMP_ROBOT robot_prefix:=$UGV_LAMP_PREFIX robot_type:=$UGV_VAE_ROBOT_TYPE target_frame:=$WORLD_FRAME sensor_frame:=$UGV_LIDAR_FRAME output_namespace:=$UGV_LAMP_ROBOT/reconstructed"
  send_plain "$SESSION:03_base_run.5" "$COMMON_SETUP" "$BASE_ROS_ENV" "rosrun mocha_core fake_rssi.py"
}
