#!/usr/bin/env bash
# Print a compact RSSI health snapshot for the current ROS master.

set -u

robots=("$@")
if [[ "${#robots[@]}" -eq 0 ]]; then
  robots=(none_iris jackal basestation)
fi

echo "RSSI monitor"
echo "ROS_MASTER_URI=${ROS_MASTER_URI:-unset}"
date "+%Y-%m-%d %H:%M:%S"
echo

if ! topic_list="$(rostopic list 2>/dev/null)"; then
  echo "ROS master is not ready."
  exit 0
fi

echo "RSSI topics:"
printf '%s\n' "$topic_list" | grep -E '/ddb/tplink/rssi/|rssi|client_stats|status_agg' || echo "  none"
echo

for robot in "${robots[@]}"; do
  topic="/ddb/tplink/rssi/$robot"
  echo "== $topic =="
  if printf '%s\n' "$topic_list" | grep -qx "$topic"; then
    output="$(timeout 2s rostopic echo -n 1 "$topic" 2>/dev/null || true)"
    if [[ -n "$output" ]]; then
      printf '%s\n' "$output"
    else
      echo "topic exists, no message received in 2s"
    fi
  else
    echo "missing"
  fi
  echo
done

echo "RSSI/MOCHA nodes:"
rosnode list 2>/dev/null | grep -Ei 'rssi|tplink|database|comm|integrate|fake' || echo "  none"
