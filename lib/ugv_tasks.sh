#!/usr/bin/env bash
# lib/ugv_tasks.sh
# UGV runtime and monitor tasks

start_ugv_runtime() {
  local panes=8
  if [[ "$RUN_ONLY" == "all" ]]; then
    panes=9
  fi
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    panes=$((panes + 1))
  fi

  make_window "02_ugv_run" "$panes"
  send_logged "$SESSION:02_ugv_run.0" "ugv_roscore" "$COMMON_SETUP" "$UGV_ROS_ENV" "roscore -p 11312" false
  send_logged "$SESSION:02_ugv_run.1" "ugv_gazebo" "$COMMON_SETUP" "$UGV_ROS_ENV" "roslaunch gazebo_ros empty_world.launch world_name:='$SIM_WORLD_FILE' gui:=false paused:=false use_sim_time:=true"
  send_logged "$SESSION:02_ugv_run.2" "ugv_mocha_jackal" "$COMMON_SETUP" "$UGV_ROS_ENV" "$WAIT_FOR_GAZEBO; JACKAL_LASER_3D=1 roslaunch mocha_launch jackal.launch $MOCHA_ROBOT_CONFIG_ARG joystick:=false x:=1"
  send_logged "$SESSION:02_ugv_run.3" "ugv_super_lio" "$COMMON_SETUP" "$UGV_ROS_ENV" "$WAIT_FOR_UGV_SENSORS; roslaunch super_lio M2DGR.launch rviz:=false"
  send_logged "$SESSION:02_ugv_run.4" "ugv_tf_tree" "$COMMON_SETUP" "$UGV_ROS_ENV" "roslaunch super_lio_lamp_adapter robot_tf.launch robot_name:=$UGV_LAMP_ROBOT odom_topic:=$UGV_ODOM_TOPIC world_to_map_x:=1 world_to_map_y:=0 world_to_map_z:=0"
  send_logged "$SESSION:02_ugv_run.5" "ugv_vae_keyframes" "$VAE_SETUP" "$UGV_ROS_ENV" "$WAIT_FOR_UGV_LIO_OUTPUTS; roslaunch super_lio_lamp_adapter local_vae_keyframe_pipeline.launch robot_namespace:=$UGV_MOCHA_ROBOT robot_id:=$UGV_MOCHA_ROBOT robot_type:=ground point_cloud_topic:=$UGV_VAE_POINT_TOPIC odom_topic:=$UGV_ODOM_TOPIC keyframe_vae_topic:=/keyframe_vae"
  send_logged "$SESSION:02_ugv_run.6" "ugv_local_lamp_input" "$COMMON_SETUP" "$UGV_ROS_ENV" "$WAIT_FOR_UGV_LIO_OUTPUTS; roslaunch super_lio_lamp_adapter local_lio_to_lamp.launch robot_namespace:=$UGV_LAMP_ROBOT robot_id:=$UGV_MOCHA_ROBOT robot_prefix:=$UGV_LAMP_PREFIX odom_topic:=$UGV_ODOM_TOPIC cloud_topic:=$UGV_CLOUD_BODY_TOPIC fixed_frame_id:=$WORLD_FRAME"
  send_logged "$SESSION:02_ugv_run.7" "ugv_jackal_tf_bridge" "$COMMON_SETUP" "$UGV_ROS_ENV" "rosrun tf2_ros static_transform_publisher 0 0 0 0 0 0 1 base_link jackal_base_link"
  if [[ "$RUN_ONLY" == "all" ]]; then
    send_logged "$SESSION:02_ugv_run.8" "ugv_receive_uav" "$VAE_SETUP" "$UGV_ROS_ENV" "roslaunch super_lio_lamp_adapter received_keyframe_vae_to_lamp.launch source_mocha_robot:=$UAV_MOCHA_ROBOT source_robot_id:=$UAV_MOCHA_ROBOT lamp_robot_namespace:=$UAV_LAMP_ROBOT robot_prefix:=$UAV_LAMP_PREFIX robot_type:=aerial target_frame:=$WORLD_FRAME sensor_frame:=$UAV_LIDAR_FRAME output_namespace:=$UAV_LAMP_ROBOT/reconstructed"
  fi
  if [[ "$LAMP_MODE" == "distributed" ]]; then
    local fusion_pane=8
    local base1_relays
    if [[ "$RUN_ONLY" == "all" ]]; then
      fusion_pane=9
    fi
    base1_relays="$(distributed_base1_compat_relays "$UGV_FUSION_NAMESPACE" "ugv_fusion")"
    send_logged "$SESSION:02_ugv_run.$fusion_pane" "ugv_lamp_fusion" "$COMMON_SETUP" "$UGV_ROS_ENV" "rosparam load '$BASE_LAMP_ROBOT_NAMES_CONFIG' /base1/lamp; $base1_relays roslaunch lamp turn_on_lamp_base.launch robot_namespace:=$UGV_FUSION_NAMESPACE robot_names_config:='$BASE_LAMP_ROBOT_NAMES_CONFIG' rssi_parameters_config:='$BASE_RSSI_PARAMETERS_CONFIG' run_loop_closure_batcher:=$RUN_GNN_BATCHER"
  fi
}

start_ugv_monitors() {
  make_window "05_ugv_mon" 6
  send_plain "$SESSION:05_ugv_mon.0" "$COMMON_SETUP" "$UGV_ROS_ENV" "watch -n 1 \"rostopic list | grep -E 'keyframe|vae|lio|lamp|ddb|rssi|reconstructed|octvox|cloud' || true\""
  send_plain "$SESSION:05_ugv_mon.1" "$COMMON_SETUP" "$UGV_ROS_ENV" "rostopic hz /keyframe_vae $UGV_ODOM_TOPIC $UGV_VAE_POINT_TOPIC"
  send_plain "$SESSION:05_ugv_mon.2" "$COMMON_SETUP" "$UGV_ROS_ENV" "rostopic echo --noarr /keyframe_vae"
  if [[ "$RUN_ONLY" == "all" ]]; then
    if [[ "$LAMP_MODE" == "distributed" ]]; then
      send_plain "$SESSION:05_ugv_mon.3" "$COMMON_SETUP" "$UGV_ROS_ENV" "rostopic hz /$UAV_MOCHA_ROBOT/keyframe_vae /$UGV_FUSION_NAMESPACE/lamp/pose_graph /$UAV_LAMP_ROBOT/lamp/pose_graph_incremental"
    else
      send_plain "$SESSION:05_ugv_mon.3" "$COMMON_SETUP" "$UGV_ROS_ENV" "rostopic hz /$UAV_MOCHA_ROBOT/keyframe_vae /$UAV_LAMP_ROBOT/reconstructed/cloud_body /$UAV_LAMP_ROBOT/lamp/pose_graph_incremental"
    fi
  else
    if [[ "$LAMP_MODE" == "distributed" ]]; then
      send_plain "$SESSION:05_ugv_mon.3" "$COMMON_SETUP" "$UGV_ROS_ENV" "rostopic hz /$UGV_LAMP_ROBOT/lamp/pose_graph_incremental /$UGV_FUSION_NAMESPACE/lamp/pose_graph /$UGV_FUSION_NAMESPACE/lamp/keyed_scans"
    else
      send_plain "$SESSION:05_ugv_mon.3" "$COMMON_SETUP" "$UGV_ROS_ENV" "rostopic hz /$UGV_LAMP_ROBOT/keyframe /$UGV_LAMP_ROBOT/lamp/pose_graph_incremental /$UGV_LAMP_ROBOT/lamp/keyed_scans"
    fi
  fi
  send_plain "$SESSION:05_ugv_mon.4" "$COMMON_SETUP" "$UGV_ROS_ENV" "rosrun tf tf_monitor $WORLD_FRAME $UGV_LIDAR_FRAME"
  send_plain "$SESSION:05_ugv_mon.5" "$COMMON_SETUP" "$UGV_ROS_ENV" "watch -n 2 \"rosnode list | sort | grep -E 'mocha|super|vae|lamp|keyframe|tf|rssi' || true\""
}
