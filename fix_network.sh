#!/bin/bash
# Automated network fix script for Docker DNS and web proxy issues
# Usage: sudo bash fix_network.sh

set -e

# 1. Fix Docker DNS
DOCKER_DAEMON_JSON="/etc/docker/daemon.json"
echo "Setting Docker DNS to 8.8.8.8 and 1.1.1.1..."
if [ -f "$DOCKER_DAEMON_JSON" ]; then
    sudo jq '.dns = ["8.8.8.8", "1.1.1.1"]' "$DOCKER_DAEMON_JSON" > /tmp/daemon.json && sudo mv /tmp/daemon.json "$DOCKER_DAEMON_JSON"
else
    echo '{"dns": ["8.8.8.8", "1.1.1.1"]}' | sudo tee "$DOCKER_DAEMON_JSON"
fi

# 2. Restart Docker
sudo systemctl restart docker
sleep 5

echo "Docker restarted."

# 3. Prune unused Docker networks
sudo docker network prune -f

echo "Pruned unused Docker networks."

# 4. Check for web proxy containers (Caddy, Nginx, Traefik)
PROXIES=(caddy nginx traefik)
RUNNING_PROXY=""
for proxy in "${PROXIES[@]}"; do
    if sudo docker ps --format '{{.Image}}' | grep -i "$proxy"; then
        RUNNING_PROXY="$proxy"
        echo "$proxy proxy is running."
    fi
done
if [ -z "$RUNNING_PROXY" ]; then
    echo "No web proxy container (Caddy, Nginx, Traefik) is running! Please start your web proxy container."
fi

# 5. Check if ports 80/443 are listening
if ss -tuln | grep ':80 '; then
    echo "Port 80 is listening."
else
    echo "Port 80 is NOT listening!"
fi
if ss -tuln | grep ':443 '; then
    echo "Port 443 is listening."
else
    echo "Port 443 is NOT listening!"
fi

# 6. Optionally disable UFW for testing
read -p "Do you want to temporarily disable UFW to test connectivity? (y/N): " DISABLE_UFW
if [[ "$DISABLE_UFW" =~ ^[Yy]$ ]]; then
    sudo ufw disable
    echo "UFW disabled. Test your services, then re-enable with 'sudo ufw enable'."
fi

echo "Network fix script complete. Please check your services and DNS resolution."
