#!/usr/bin/env bash
# lib/uav_tasks.sh
# UAV runtime tasks.

# shellcheck source=/home/nlg/all_ws/run/lib/tmux_utils.sh
source "$SCRIPT_DIR/lib/tmux_utils.sh"

start_uav_runtime() {
  local panes=6
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    panes=$((panes + 1))
    if [[ "$RUN_ONLY" == "all" ]]; then
      panes=$((panes + 1))
    fi
  fi

  make_window "01_uav_run" "$panes"
  send_plain "$SESSION:01_uav_run.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "roscore -p 11313" false
  send_plain "$SESSION:01_uav_run.1" "$COMMON_SETUP" "$UAV_ROS_ENV" "test -f '$PX4_UAV_SDF' && roslaunch mocha_launch iris.launch $MOCHA_ROBOT_CONFIG_ARG sdf:='$PX4_UAV_SDF' world:='$SIM_WORLD_FILE' gui:=false x:=$UAV_SPAWN_X y:=$UAV_SPAWN_Y z:=$UAV_SPAWN_Z R:=$UAV_SPAWN_ROLL P:=$UAV_SPAWN_PITCH Y:=$UAV_SPAWN_YAW"
  send_plain "$SESSION:01_uav_run.2" "$COMMON_SETUP" "$UAV_ROS_ENV" "$WAIT_FOR_UAV_SENSORS; roslaunch super_lio velodyne_16.launch lidar_topic:=$UAV_LIDAR_TOPIC imu_topic:=$UAV_IMU_TOPIC rviz:=false"
  send_plain "$SESSION:01_uav_run.3" "$COMMON_SETUP" "$UAV_ROS_ENV" "roslaunch super_lio_lamp_adapter robot_tf.launch robot_name:=$UAV_LAMP_ROBOT odom_topic:=$UAV_ODOM_TOPIC world_to_map_x:=$UAV_MAP_X world_to_map_y:=$UAV_MAP_Y world_to_map_z:=$UAV_MAP_Z"
  send_plain "$SESSION:01_uav_run.4" "$VAE_SETUP" "$UAV_ROS_ENV" "$WAIT_FOR_UAV_LIO_OUTPUTS; roslaunch super_lio_lamp_adapter local_vae_keyframe_pipeline.launch robot_namespace:=$UAV_MOCHA_ROBOT robot_id:=$UAV_MOCHA_ROBOT robot_type:=$UAV_VAE_ROBOT_TYPE point_cloud_topic:=$UAV_VAE_POINT_TOPIC odom_topic:=$UAV_ODOM_TOPIC keyframe_vae_topic:=/keyframe_vae"
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    send_plain "$SESSION:01_uav_run.5" "$VAE_SETUP" "$UAV_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$UAV_MOCHA_ROBOT source_robot_id:=$UAV_MOCHA_ROBOT lamp_robot_namespace:=$UAV_LAMP_ROBOT robot_prefix:=$UAV_LAMP_PREFIX robot_type:=$UAV_VAE_ROBOT_TYPE keyframe_vae_topic:=/$UAV_MOCHA_ROBOT/keyframe_vae target_frame:=$WORLD_FRAME sensor_frame:=$UAV_LIDAR_FRAME output_namespace:=$UAV_LAMP_ROBOT/reconstructed_local"
  else
    send_plain "$SESSION:01_uav_run.5" "$COMMON_SETUP" "$UAV_ROS_ENV" "$WAIT_FOR_UAV_LIO_OUTPUTS; roslaunch super_lio_lamp_adapter local_lio_to_lamp.launch robot_namespace:=$UAV_LAMP_ROBOT robot_id:=$UAV_MOCHA_ROBOT robot_prefix:=$UAV_LAMP_PREFIX odom_topic:=$UAV_ODOM_TOPIC cloud_topic:=$UAV_CLOUD_BODY_TOPIC fixed_frame_id:=$WORLD_FRAME"
  fi
  if [[ "$RUN_ONLY" == "all" && "$LAMP_MODE" == "distributed" ]]; then
    send_plain "$SESSION:01_uav_run.6" "$VAE_SETUP" "$UAV_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$UGV_MOCHA_ROBOT source_robot_id:=$UGV_MOCHA_ROBOT lamp_robot_namespace:=$UGV_LAMP_ROBOT robot_prefix:=$UGV_LAMP_PREFIX robot_type:=$UGV_VAE_ROBOT_TYPE target_frame:=$WORLD_FRAME sensor_frame:=$UGV_LIDAR_FRAME output_namespace:=$UGV_LAMP_ROBOT/reconstructed"
  fi
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    local fusion_pane=6
    local base1_relays
    if [[ "$RUN_ONLY" == "all" ]]; then
      fusion_pane=7
    fi
    base1_relays="$(distributed_base1_compat_relays "$UAV_FUSION_NAMESPACE" "uav_fusion")"
    send_plain "$SESSION:01_uav_run.$fusion_pane" "$COMMON_SETUP" "$UAV_ROS_ENV" "rosparam load '$BASE_LAMP_ROBOT_NAMES_CONFIG' /base1/lamp; $base1_relays roslaunch lamp turn_on_lamp_base.launch robot_namespace:=$UAV_FUSION_NAMESPACE robot_names_config:='$BASE_LAMP_ROBOT_NAMES_CONFIG' rssi_parameters_config:='$BASE_RSSI_PARAMETERS_CONFIG' run_loop_closure_batcher:=$RUN_GNN_BATCHER"
  fi
}
