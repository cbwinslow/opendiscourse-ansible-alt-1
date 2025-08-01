#!/bin/bash
# test_local_ports.sh
# Diagnostic script for web ports and proxy containers

set -e

echo "==== Checking if anything is listening on ports 80 and 443 ===="
ss -tuln | grep -E ':80 |:443 ' || echo "No listeners found on 80/443 with ss."
netstat -tuln | grep -E ':80 |:443 ' || echo "No listeners found on 80/443 with netstat."

echo "\n==== Testing HTTP/HTTPS connectivity to localhost ===="
curl -I http://localhost:80 || echo "Could not connect to localhost:80"
curl -I https://localhost:443 || echo "Could not connect to localhost:443"

echo "\n==== Listing running Docker containers and their port mappings ===="
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

echo "\n==== Checking for Caddy, Traefik, or Nginx processes ===="
ps aux | grep -E 'caddy|traefik|nginx' | grep -v grep || echo "No proxy processes found."

echo "\n==== Showing recent logs for containers exposing 80/443 ===="
for cid in $(docker ps -q); do
  ports=$(docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}}{{println $p}}{{end}}' $cid)
  if echo "$ports" | grep -qE '80/tcp|443/tcp'; then
    name=$(docker inspect --format='{{.Name}}' $cid | sed 's/^\///')
    echo "\n--- Logs for $name ---"
    docker logs --tail 20 $cid
  fi
done

echo "\n==== Done. Review output above for diagnostics. ===="
