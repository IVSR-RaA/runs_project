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
  $0              Start runtime tmux session and attach.
  $0 --only ugv   Start only one runtime group: uav, ugv, husky, base, or all.
  $0 --lamp-mode base|distributed
                  LAMP topology. base is the current base-station aggregator.
                  distributed runs one fusion LAMP process on each robot master.
  $0 --distributed
                  Shortcut for --lamp-mode distributed.
  $0 --mission FILE
                  Load robot waypoints from one MRM mission YAML file.
                  The selected Jackal, Husky, and UAV groups use their
                  respective sections from that file.
  $0 --ugv-mission FILE --husky-mission FILE --uav-mission FILE
                  Load independent mission YAML files for Jackal, Husky, and
                  UAV. These options can also override --mission per robot.
  USE_SOLID_LOOP_CONDITION=true $0 --no-attach
                  Enable SOLiD descriptor filtering before LAMP loop verification.
  HUSKY_START_DELAY=300 $0 --distributed --no-attach
                  Start the Husky runtime group five minutes after the others.
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
        session_state_dir=""
        if [[ -f "$SESSION_STATE_FILE" ]]; then
          session_state_dir="$(<"$SESSION_STATE_FILE")"
        fi
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
      if [[ -n "${session_state_dir:-}" && "$session_state_dir" == /tmp/run_mrm_* ]]; then
        rm -rf "$session_state_dir"
      fi
      rm -f "$SESSION_STATE_FILE"
      exit 0
      ;;
    --attach) tmux attach -t "$SESSION"; exit 0 ;;
    --no-attach) ATTACH_ON_START="false"; shift ;;
    --only) RUN_ONLY="${2:-}"; shift 2 ;;
    --only=*) RUN_ONLY="${1#*=}"; shift ;;
    --lamp-mode) LAMP_MODE="${2:-}"; shift 2 ;;
    --lamp-mode=*) LAMP_MODE="${1#*=}"; shift ;;
    --distributed) LAMP_MODE="distributed"; shift ;;
    --mission)
      if [[ -z "${2:-}" ]]; then
        echo "[usage][ERROR] --mission requires a YAML file." >&2
        exit 1
      fi
      MRM_MISSION_FILE="$2"
      UGV_MISSION_FILE="$2"
      HUSKY_MISSION_FILE="$2"
      UAV_MISSION_FILE="$2"
      UGV_ENABLE_CMU_PLANNER="true"
      UGV_CMU_RUN_WAYPOINTS="true"
      HUSKY_ENABLE_CMU_PLANNER="true"
      HUSKY_CMU_RUN_WAYPOINTS="true"
      UAV_ENABLE_SEQUENCE_CONTROLLER="true"
      shift 2
      ;;
    --mission=*)
      MRM_MISSION_FILE="${1#*=}"
      if [[ -z "$MRM_MISSION_FILE" ]]; then
        echo "[usage][ERROR] --mission requires a YAML file." >&2
        exit 1
      fi
      UGV_MISSION_FILE="$MRM_MISSION_FILE"
      HUSKY_MISSION_FILE="$MRM_MISSION_FILE"
      UAV_MISSION_FILE="$MRM_MISSION_FILE"
      UGV_ENABLE_CMU_PLANNER="true"
      UGV_CMU_RUN_WAYPOINTS="true"
      HUSKY_ENABLE_CMU_PLANNER="true"
      HUSKY_CMU_RUN_WAYPOINTS="true"
      UAV_ENABLE_SEQUENCE_CONTROLLER="true"
      shift
      ;;
    --ugv-mission)
      if [[ -z "${2:-}" ]]; then
        echo "[usage][ERROR] --ugv-mission requires a YAML file." >&2
        exit 1
      fi
      UGV_MISSION_FILE="$2"
      UGV_ENABLE_CMU_PLANNER="true"
      UGV_CMU_RUN_WAYPOINTS="true"
      shift 2
      ;;
    --ugv-mission=*)
      UGV_MISSION_FILE="${1#*=}"
      if [[ -z "$UGV_MISSION_FILE" ]]; then
        echo "[usage][ERROR] --ugv-mission requires a YAML file." >&2
        exit 1
      fi
      UGV_ENABLE_CMU_PLANNER="true"
      UGV_CMU_RUN_WAYPOINTS="true"
      shift
      ;;
    --husky-mission)
      if [[ -z "${2:-}" ]]; then
        echo "[usage][ERROR] --husky-mission requires a YAML file." >&2
        exit 1
      fi
      HUSKY_MISSION_FILE="$2"
      HUSKY_ENABLE_CMU_PLANNER="true"
      HUSKY_CMU_RUN_WAYPOINTS="true"
      shift 2
      ;;
    --husky-mission=*)
      HUSKY_MISSION_FILE="${1#*=}"
      if [[ -z "$HUSKY_MISSION_FILE" ]]; then
        echo "[usage][ERROR] --husky-mission requires a YAML file." >&2
        exit 1
      fi
      HUSKY_ENABLE_CMU_PLANNER="true"
      HUSKY_CMU_RUN_WAYPOINTS="true"
      shift
      ;;
    --uav-mission)
      if [[ -z "${2:-}" ]]; then
        echo "[usage][ERROR] --uav-mission requires a YAML file." >&2
        exit 1
      fi
      UAV_MISSION_FILE="$2"
      UAV_ENABLE_SEQUENCE_CONTROLLER="true"
      shift 2
      ;;
    --uav-mission=*)
      UAV_MISSION_FILE="${1#*=}"
      if [[ -z "$UAV_MISSION_FILE" ]]; then
        echo "[usage][ERROR] --uav-mission requires a YAML file." >&2
        exit 1
      fi
      UAV_ENABLE_SEQUENCE_CONTROLLER="true"
      shift
      ;;
    *) echo "[usage][ERROR] unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

case "$RUN_ONLY" in
  all | uav | ugv | husky | base) ;;
  *) echo "[usage][ERROR] --only must be one of: all, uav, ugv, husky, base" >&2; exit 1 ;;
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
RUN_HUSKY_GROUP=false
RUN_BASE_GROUP=false
case "$RUN_ONLY" in
  all)
    RUN_UAV_GROUP=true
    RUN_UGV_GROUP=true
    RUN_HUSKY_GROUP=true
    if [[ "$LAMP_MODE" == "base" ]]; then RUN_BASE_GROUP=true; fi
    ;;
  uav) RUN_UAV_GROUP=true ;;
  ugv) RUN_UGV_GROUP=true ;;
  husky) RUN_HUSKY_GROUP=true ;;
  base) RUN_BASE_GROUP=true ;;
esac

if [[ "$LAMP_MODE" == "distributed" && -z "$RSSI_ROBOTS_WAS_SET" ]]; then
  RSSI_ROBOTS="$UAV_MOCHA_ROBOT $UGV_MOCHA_ROBOT $HUSKY_MOCHA_ROBOT"
fi

echo "[start] session=$SESSION run_only=$RUN_ONLY lamp_mode=$LAMP_MODE state_dir=$SESSION_STATE_DIR"
echo "[tmux] checking existing session: $SESSION"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  if [[ "$ATTACH_ON_START" == "true" ]]; then
    tmux attach -t "$SESSION"
  else
    echo "[tmux] session already exists: $SESSION"
  fi
  exit 0
fi

mkdir -p "$SESSION_STATE_DIR"
printf '%s\n' "$SESSION_STATE_DIR" >"$SESSION_STATE_FILE"

if ! prepare_camera_assets; then
  echo "[camera] fatal camera asset preparation failed." >&2
  exit 1
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
# shellcheck source=/home/nlg/all_ws/run/lib/husky_tasks.sh
source "$SCRIPT_DIR/lib/husky_tasks.sh"
# shellcheck source=/home/nlg/all_ws/run/lib/base_tasks.sh
source "$SCRIPT_DIR/lib/base_tasks.sh"
# shellcheck source=/home/nlg/all_ws/run/lib/common_tasks.sh
source "$SCRIPT_DIR/lib/common_tasks.sh"

if ! prepare_mission_assets; then
  echo "[mission] fatal mission preparation failed." >&2
  exit 1
fi

if ! preflight_checks; then
  echo "[preflight] fatal checks failed; fix errors above or override the related environment variables." >&2
  exit 1
fi

if [[ "$MANAGE_LOOPBACK_ALIASES" == "true" ]]; then
  needs_loopback_sudo=false
  if [[ "$RUN_UAV_GROUP" == "true" ]]; then
    ip -o addr show dev lo | grep -q "inet $UAV_IP/" || needs_loopback_sudo=true
  fi
  if [[ "$RUN_UGV_GROUP" == "true" ]]; then
    ip -o addr show dev lo | grep -q "inet $UGV_IP/" || needs_loopback_sudo=true
  fi
  if [[ "$RUN_HUSKY_GROUP" == "true" ]]; then
    ip -o addr show dev lo | grep -q "inet $HUSKY_IP/" || needs_loopback_sudo=true
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
  if [[ "$RUN_HUSKY_GROUP" == "true" ]]; then ensure_loopback_alias "$HUSKY_IP/24" || exit 1; fi
  if [[ "$RUN_BASE_GROUP" == "true" ]]; then ensure_loopback_alias "$BASE_IP/24" || exit 1; fi
else
  echo "[net] skipping loopback alias management; using configured host IPs."
fi

prepare_mocha_config_arg
prepare_lamp_robot_names_config
prepare_base_rssi_parameters_config

echo "[tmux] creating session: $SESSION"
tmux new-session -d -s "$SESSION" -n "00_status"
tmux set-option -t "$SESSION" mouse on >/dev/null
tmux set-option -t "$SESSION" history-limit 50000 >/dev/null
tmux set-window-option -t "$SESSION" remain-on-exit on >/dev/null

start_status_window
# start care here----------------------------------------------------------------------------
if [[ "$RUN_UAV_GROUP" == "true" ]]; then
  start_uav_runtime
fi

if [[ "$RUN_UGV_GROUP" == "true" ]]; then
  start_ugv_runtime
fi

if [[ "$RUN_HUSKY_GROUP" == "true" ]]; then
  start_husky_runtime
fi

if [[ "$RUN_BASE_GROUP" == "true" ]]; then
  start_base_runtime
fi
# end care here----------------------------------------------------------------------------
start_manual_shells

tmux select-window -t "$SESSION:00_status"
if [[ "$ATTACH_ON_START" == "true" ]]; then
  tmux attach -t "$SESSION"
else
  echo "[tmux] started detached session: $SESSION"
  echo "[tmux] no run log files are written; inspect live output in tmux panes."
fi
