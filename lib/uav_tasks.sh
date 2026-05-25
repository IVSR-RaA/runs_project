#!/usr/bin/env bash
# lib/uav_tasks.sh
# UAV runtime and monitor tasks

start_uav_runtime() {
  local panes=6
  if [[ "$RUN_ONLY" == "all" ]]; then
    panes=7
  fi
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    panes=$((panes + 1))
  fi

  make_window "01_uav_run" "$panes"
  send_plain "$SESSION:01_uav_run.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "roscore -p 11313" false
  send_plain "$SESSION:01_uav_run.1" "$COMMON_SETUP" "$UAV_ROS_ENV" "test -f '$PX4_UAV_SDF' && roslaunch mocha_launch iris.launch $MOCHA_ROBOT_CONFIG_ARG sdf:='$PX4_UAV_SDF' world:='$SIM_WORLD_FILE' gui:=false x:=$UAV_SPAWN_X y:=$UAV_SPAWN_Y z:=$UAV_SPAWN_Z R:=$UAV_SPAWN_ROLL P:=$UAV_SPAWN_PITCH Y:=$UAV_SPAWN_YAW"
  send_plain "$SESSION:01_uav_run.2" "$COMMON_SETUP" "$UAV_ROS_ENV" "$WAIT_FOR_UAV_SENSORS; roslaunch super_lio velodyne_16.launch lidar_topic:=$UAV_LIDAR_TOPIC imu_topic:=$UAV_IMU_TOPIC rviz:=false"
  send_plain "$SESSION:01_uav_run.3" "$COMMON_SETUP" "$UAV_ROS_ENV" "roslaunch super_lio_lamp_adapter robot_tf.launch robot_name:=$UAV_LAMP_ROBOT odom_topic:=$UAV_ODOM_TOPIC world_to_map_x:=$UAV_MAP_X world_to_map_y:=$UAV_MAP_Y world_to_map_z:=$UAV_MAP_Z"
  send_plain "$SESSION:01_uav_run.4" "$VAE_SETUP" "$UAV_ROS_ENV" "$WAIT_FOR_UAV_LIO_OUTPUTS; roslaunch super_lio_lamp_adapter local_vae_keyframe_pipeline.launch robot_namespace:=$UAV_MOCHA_ROBOT robot_id:=$UAV_MOCHA_ROBOT robot_type:=aerial point_cloud_topic:=$UAV_VAE_POINT_TOPIC odom_topic:=$UAV_ODOM_TOPIC keyframe_vae_topic:=/keyframe_vae"
  send_plain "$SESSION:01_uav_run.5" "$COMMON_SETUP" "$UAV_ROS_ENV" "$WAIT_FOR_UAV_LIO_OUTPUTS; roslaunch super_lio_lamp_adapter local_lio_to_lamp.launch robot_namespace:=$UAV_LAMP_ROBOT robot_id:=$UAV_MOCHA_ROBOT robot_prefix:=$UAV_LAMP_PREFIX odom_topic:=$UAV_ODOM_TOPIC cloud_topic:=$UAV_CLOUD_BODY_TOPIC fixed_frame_id:=$WORLD_FRAME"
  if [[ "$RUN_ONLY" == "all" ]]; then
    send_plain "$SESSION:01_uav_run.6" "$VAE_SETUP" "$UAV_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$UGV_MOCHA_ROBOT source_robot_id:=$UGV_MOCHA_ROBOT lamp_robot_namespace:=$UGV_LAMP_ROBOT robot_prefix:=$UGV_LAMP_PREFIX robot_type:=ground target_frame:=$WORLD_FRAME sensor_frame:=$UGV_LIDAR_FRAME output_namespace:=$UGV_LAMP_ROBOT/reconstructed"
  fi
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    local fusion_pane=6
    if [[ "$RUN_ONLY" == "all" ]]; then
      fusion_pane=7
    fi
    start_distributed_lamp_fusion "$SESSION:01_uav_run.$fusion_pane" "$UAV_ROS_ENV" "$UAV_FUSION_NAMESPACE" "uav_fusion"
  fi
}

start_uav_monitors() {
  make_window "04_uav_mon" 6
  send_plain "$SESSION:04_uav_mon.0" "$COMMON_SETUP" "$UAV_ROS_ENV" "watch -n 1 \"rostopic list | grep -E 'keyframe|vae|lio|lamp|ddb|rssi|reconstructed|octvox|cloud' || true\""
  send_plain "$SESSION:04_uav_mon.1" "$COMMON_SETUP" "$UAV_ROS_ENV" "rostopic hz /keyframe_vae $UAV_ODOM_TOPIC $UAV_VAE_POINT_TOPIC"
  send_plain "$SESSION:04_uav_mon.2" "$COMMON_SETUP" "$UAV_ROS_ENV" "rostopic echo --noarr /keyframe_vae"
  if [[ "$RUN_ONLY" == "all" ]]; then
    if [[ "$LAMP_MODE" == "distributed" ]]; then
      send_plain "$SESSION:04_uav_mon.3" "$COMMON_SETUP" "$UAV_ROS_ENV" "rostopic hz /$UGV_MOCHA_ROBOT/keyframe_vae /$UAV_FUSION_NAMESPACE/lamp/pose_graph /$UGV_LAMP_ROBOT/lamp/pose_graph_incremental"
    else
      send_plain "$SESSION:04_uav_mon.3" "$COMMON_SETUP" "$UAV_ROS_ENV" "rostopic hz /$UGV_MOCHA_ROBOT/keyframe_vae /$UGV_LAMP_ROBOT/reconstructed/cloud_body /$UGV_LAMP_ROBOT/lamp/pose_graph_incremental"
    fi
  else
    if [[ "$LAMP_MODE" == "distributed" ]]; then
      send_plain "$SESSION:04_uav_mon.3" "$COMMON_SETUP" "$UAV_ROS_ENV" "rostopic hz /$UAV_LAMP_ROBOT/lamp/pose_graph_incremental /$UAV_FUSION_NAMESPACE/lamp/pose_graph /$UAV_FUSION_NAMESPACE/lamp/keyed_scans"
    else
      send_plain "$SESSION:04_uav_mon.3" "$COMMON_SETUP" "$UAV_ROS_ENV" "rostopic hz /$UAV_LAMP_ROBOT/keyframe /$UAV_LAMP_ROBOT/lamp/pose_graph_incremental /$UAV_LAMP_ROBOT/lamp/keyed_scans"
    fi
  fi
  send_plain "$SESSION:04_uav_mon.4" "$COMMON_SETUP" "$UAV_ROS_ENV" "rosrun tf tf_monitor $WORLD_FRAME $UAV_LIDAR_FRAME"
  send_plain "$SESSION:04_uav_mon.5" "$COMMON_SETUP" "$UAV_ROS_ENV" "watch -n 2 \"rosnode list | sort | grep -E 'mocha|super|vae|lamp|keyframe|tf|rssi' || true\""
}
