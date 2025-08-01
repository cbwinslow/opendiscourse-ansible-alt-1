#!/bin/bash
# monitor_network_changes.sh
# Monitors network interfaces and routes for changes that may interrupt VS Code/Copilot

LOGFILE="/tmp/network_changes.log"

prev_ifconfig=""
prev_route=""

while true; do
  curr_ifconfig=$(ip addr show)
  curr_route=$(ip route show)

  if [[ "$curr_ifconfig" != "$prev_ifconfig" ]]; then
    echo "\n--- Network interface change detected at $(date) ---" | tee -a "$LOGFILE"
    echo "$curr_ifconfig" | tee -a "$LOGFILE"
    prev_ifconfig="$curr_ifconfig"
  fi

  if [[ "$curr_route" != "$prev_route" ]]; then
    echo "\n--- Routing table change detected at $(date) ---" | tee -a "$LOGFILE"
    echo "$curr_route" | tee -a "$LOGFILE"
    prev_route="$curr_route"
  fi

  sleep 10
done
