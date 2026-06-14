#!/usr/bin/env bash
# lib/tmux_utils.sh
# Tmux utility functions

kill_process_tree() {
  local signal="$1"
  local pid="$2"
  local child
  local pgid

  while IFS= read -r child; do
    if [[ -n "$child" ]]; then
      kill_process_tree "$signal" "$child"
    fi
  done < <(pgrep -P "$pid" 2>/dev/null || true)

  pgid="$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d '[:space:]' || true)"
  if [[ -n "$pgid" ]]; then
    kill "-$signal" -- "-$pgid" 2>/dev/null || true
  fi
  kill "-$signal" "$pid" 2>/dev/null || true
}

kill_mocha_port_listeners() {
  local signal="$1"
  local pid
  local cmd

  while IFS= read -r pid; do
    [[ -n "$pid" ]] || continue
    cmd="$(ps -p "$pid" -o cmd= 2>/dev/null || true)"
    if [[ "$cmd" == *"$WS/src/mocha_tplink/"* ]]; then
      kill_process_tree "$signal" "$pid"
    fi
  done < <(
    ss -ltnp 2>/dev/null |
      sed -nE 's/.*:(1234|2234|6234|7234)[[:space:]].*pid=([0-9]+).*/\2/p' |
      sort -u
  )
}

kill_gazebo_port_listeners() {
  local signal="$1"
  local uri
  local port
  local ports=()
  local pid
  local cmd

  for uri in "$UAV_GAZEBO_MASTER_URI" "$UGV_GAZEBO_MASTER_URI" "$HUSKY_GAZEBO_MASTER_URI"; do
    port="${uri##*:}"
    port="${port%%/*}"
    if [[ "$port" =~ ^[0-9]+$ ]]; then
      ports+=("$port")
    fi
  done

  while IFS= read -r pid; do
    [[ -n "$pid" ]] || continue
    cmd="$(ps -p "$pid" -o cmd= 2>/dev/null || true)"
    if [[ "$cmd" == *"gzserver"* ]]; then
      kill_process_tree "$signal" "$pid"
    fi
  done < <(
    for port in "${ports[@]}"; do
      ss -ltnp 2>/dev/null |
        sed -nE "s/.*:${port}[[:space:]].*pid=([0-9]+).*/\\1/p"
    done | sort -u
  )
}

make_window() {
  local win="$1"
  local panes="$2"

  tmux new-window -t "$SESSION" -n "$win"
  for ((i = 1; i < panes; i++)); do
    tmux split-window -t "$SESSION:$win" -h
    tmux select-layout -t "$SESSION:$win" tiled >/dev/null
  done
  tmux select-layout -t "$SESSION:$win" tiled >/dev/null
}

send_plain() {
  local pane="$1"
  local setup="$2"
  local ros_env="$3"
  local cmd="$4"
  local wait_master="${5:-true}"
  local full_cmd="$cmd"
  local escaped_cmd
  local q_ws

  if [[ "$wait_master" == "true" ]]; then
    full_cmd="$WAIT_FOR_MASTER; $cmd"
  fi

  printf -v escaped_cmd '%q' "$full_cmd"
  printf -v q_ws '%q' "$WS"

  tmux send-keys -t "$pane" "cd $q_ws; $setup; $ros_env; bash -lc $escaped_cmd" C-m
}
