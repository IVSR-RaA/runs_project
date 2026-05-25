#!/usr/bin/env bash
# run_mrm.sh
# Modularized Main Entrypoint

set -u # tránh sai chính tả biến
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Source all configuration variables first
# shellcheck source=/home/nlg/all_ws/run/lib/config.sh
source "$SCRIPT_DIR/lib/config.sh" # ------------------------------------------------------

usage() {
  cat <<EOF
Usage:
  $0              Start debug tmux session and attach.
  $0 --only ugv   Start only one runtime group: uav, ugv, base, or all.
  $0 --lamp-mode base|distributed
                  LAMP topology. base is the current base-station aggregator.
                  distributed runs one fusion LAMP process on each robot master.
  $0 --no-attach  Start tmux session detached and return.
  $0 --attach    Attach to existing session.
  $0 --kill      Kill existing session.
EOF
}

# Argument parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help | -h) usage; exit 0 ;;
    --kill)
      # shellcheck source=/home/nlg/all_ws/run/lib/tmux_utils.sh
      source "$SCRIPT_DIR/lib/tmux_utils.sh" # ------------------------------------------------------
      if tmux has-session -t "$SESSION" 2>/dev/null; then
        mapfile -t pane_pids < <(
          tmux list-panes -a -F '#{session_name}:#{pane_pid}' |
            awk -F: -v session="$SESSION" '$1 == session {print $2}'
        )
        while IFS= read -r pane; do
          tmux send-keys -t "$pane" C-c 2>/dev/null || true
        done < <(tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}' | awk -F: -v session="$SESSION" '$1 == session {print}')
        sleep 3
        for pid in "${pane_pids[@]}"; do
          kill_process_tree TERM "$pid"
        done
        sleep 1
        for pid in "${pane_pids[@]}"; do
          kill_process_tree KILL "$pid"
        done
        tmux kill-session -t "$SESSION" 2>/dev/null || true
      fi
      kill_mocha_port_listeners TERM
      kill_gazebo_port_listeners TERM
      sleep 1
      kill_mocha_port_listeners KILL
      kill_gazebo_port_listeners KILL
      if [[ "$SESSION_STATE_DIR" == /tmp/run_mrm_* ]]; then
        rm -rf "$SESSION_STATE_DIR"
      fi
      exit 0
      ;;
    --attach) tmux attach -t "$SESSION"; exit 0 ;;
    --no-attach) ATTACH_ON_START="false"; shift ;;
    --only) RUN_ONLY="${2:-}"; shift 2 ;;
    --only=*) RUN_ONLY="${1#*=}"; shift ;;
    --lamp-mode) LAMP_MODE="${2:-}"; shift 2 ;;
    --lamp-mode=*) LAMP_MODE="${1#*=}"; shift ;;
    --distributed) LAMP_MODE="distributed"; shift ;;
    *) echo "[usage][ERROR] unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

case "$RUN_ONLY" in
  all | uav | ugv | base) ;;
  *) echo "[usage][ERROR] --only must be one of: all, uav, ugv, base" >&2; exit 1 ;;
esac

case "$LAMP_MODE" in
  base | distributed) ;;
  *) echo "[usage][ERROR] --lamp-mode must be one of: base, distributed" >&2; exit 1 ;;
esac

if [[ "$LAMP_MODE" == "distributed" && "$RUN_ONLY" == "base" ]]; then
  echo "[usage][ERROR] --only base is not valid with --lamp-mode distributed; use --only uav, --only ugv, or all." >&2
  exit 1
fi

RUN_UAV_GROUP=false
RUN_UGV_GROUP=false
RUN_BASE_GROUP=false
case "$RUN_ONLY" in
  all)
    RUN_UAV_GROUP=true
    RUN_UGV_GROUP=true
    if [[ "$LAMP_MODE" == "base" ]]; then RUN_BASE_GROUP=true; fi
    ;;
  uav) RUN_UAV_GROUP=true ;;
  ugv) RUN_UGV_GROUP=true ;;
  base) RUN_BASE_GROUP=true ;;
esac

if [[ "$LAMP_MODE" == "distributed" && -z "$RSSI_ROBOTS_WAS_SET" ]]; then
  RSSI_ROBOTS="$UAV_MOCHA_ROBOT $UGV_MOCHA_ROBOT"
fi

echo "[start] session=$SESSION run_only=$RUN_ONLY lamp_mode=$LAMP_MODE state_dir=$SESSION_STATE_DIR"
if [[ "$LAMP_MODE" == "base" && ( "$RUN_ONLY" == "uav" || "$RUN_ONLY" == "ugv" ) ]]; then
  echo "[start][WARN] --only $RUN_ONLY in base mode starts local robot inputs only; RViz base map/path topics need base LAMP."
  echo "[start][WARN] Use --only $RUN_ONLY --distributed for single-robot local fusion map/path in RViz."
fi
echo "[tmux] checking existing session: $SESSION"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  if [[ "$ATTACH_ON_START" == "true" ]]; then
    tmux attach -t "$SESSION"
  else
    echo "[tmux] session already exists: $SESSION"
  fi
  exit 0
fi

# Source remaining modules
# shellcheck source=/home/nlg/all_ws/run/lib/tmux_utils.sh
source "$SCRIPT_DIR/lib/tmux_utils.sh"
# shellcheck source=/home/nlg/all_ws/run/lib/preflight.sh
source "$SCRIPT_DIR/lib/preflight.sh"
# shellcheck source=/home/nlg/all_ws/run/lib/uav_tasks.sh
source "$SCRIPT_DIR/lib/uav_tasks.sh"
# shellcheck source=/home/nlg/all_ws/run/lib/ugv_tasks.sh
source "$SCRIPT_DIR/lib/ugv_tasks.sh"
# shellcheck source=/home/nlg/all_ws/run/lib/base_tasks.sh
source "$SCRIPT_DIR/lib/base_tasks.sh"
# shellcheck source=/home/nlg/all_ws/run/lib/common_tasks.sh
source "$SCRIPT_DIR/lib/common_tasks.sh"

if ! validate_runtime_isolation; then
  echo "[config] fatal isolation checks failed; use different ROS and Gazebo masters for UGV and UAV." >&2
  exit 1
fi

if ! preflight_checks; then
  echo "[preflight] fatal checks failed; fix errors above or override the related environment variables." >&2
  exit 1
fi

needs_loopback_sudo=false
if [[ "$RUN_UAV_GROUP" == "true" ]]; then
  ip -o addr show dev lo | grep -q "inet $UAV_IP/" || needs_loopback_sudo=true
fi
if [[ "$RUN_UGV_GROUP" == "true" ]]; then
  ip -o addr show dev lo | grep -q "inet $UGV_IP/" || needs_loopback_sudo=true
fi
if [[ "$RUN_BASE_GROUP" == "true" ]]; then
  ip -o addr show dev lo | grep -q "inet $BASE_IP/" || needs_loopback_sudo=true
fi

if [[ "$needs_loopback_sudo" == "true" ]]; then
  echo "[sudo] refreshing sudo credentials for missing loopback aliases..."
  if ! sudo -v; then
    echo "[sudo][ERROR] sudo authentication is required before loopback aliases can be added." >&2
    exit 1
  fi
fi

echo "[net] checking loopback aliases..."
if [[ "$RUN_UAV_GROUP" == "true" ]]; then ensure_loopback_alias "$UAV_IP/24" || exit 1; fi
if [[ "$RUN_UGV_GROUP" == "true" ]]; then ensure_loopback_alias "$UGV_IP/24" || exit 1; fi
if [[ "$RUN_BASE_GROUP" == "true" ]]; then ensure_loopback_alias "$BASE_IP/24" || exit 1; fi

prepare_mocha_config_arg
prepare_lamp_robot_names_config
prepare_base_rssi_parameters_config

echo "[tmux] creating session: $SESSION"
tmux new-session -d -s "$SESSION" -n "00_status"
tmux set-option -t "$SESSION" mouse on >/dev/null
tmux set-option -t "$SESSION" history-limit 50000 >/dev/null
tmux set-window-option -t "$SESSION" remain-on-exit on >/dev/null

start_status_window

if [[ "$RUN_UAV_GROUP" == "true" ]]; then
  start_uav_runtime
  start_uav_monitors
fi

if [[ "$RUN_UGV_GROUP" == "true" ]]; then
  start_ugv_runtime
  start_ugv_monitors
fi

if [[ "$RUN_BASE_GROUP" == "true" ]]; then
  start_base_runtime
  start_base_monitors
fi

if [[ "$RUN_ONLY" == "all" ]]; then
  start_visual_tools
elif [[ "$RUN_ONLY" == "base" ]]; then
  start_base_visual_tools
elif [[ "$RUN_ONLY" == "uav" ]]; then
  start_uav_visual_tools
elif [[ "$RUN_ONLY" == "ugv" ]]; then
  start_ugv_visual_tools
fi

start_selected_ros_diag_windows
start_selected_manual_shells
start_rssi_monitors

tmux select-window -t "$SESSION:00_status"
if [[ "$ATTACH_ON_START" == "true" ]]; then
  tmux attach -t "$SESSION"
else
  echo "[tmux] started detached session: $SESSION"
  echo "[tmux] no run log files are written; inspect live output in tmux panes."
fi
