#!/bin/bash
# monitor_llm_service.sh
# Monitors LLM chat service containers for restarts, errors, and network changes

# List of likely LLM/chat containers (edit as needed)
CONTAINERS=$(docker ps --format '{{.Names}}' | grep -E 'openwebui|n8n|ollama|flowise|langfuse')

if [ -z "$CONTAINERS" ]; then
  echo "No LLM/chat containers found. Edit script to match your container names."
  exit 1
fi

echo "Monitoring containers: $CONTAINERS"

while true; do
  for c in $CONTAINERS; do
    echo "\n--- $c status ---"
    docker inspect --format='Status: {{.State.Status}} | RestartCount: {{.RestartCount}}' $c
    echo "Recent logs:"
    docker logs --tail 20 $c | tail -20
  done
  echo "\n--- Network interfaces ---"
  ip addr show
  echo "\n--- Docker networks ---"
  docker network ls
  echo "\n--- Timestamp: $(date) ---"
  sleep 30
  clear
  echo "Press Ctrl+C to stop monitoring."
done
