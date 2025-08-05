#!/bin/bash
# Network Diagnostic Script for Local AI Packaged Deployment
# Usage: sudo bash network_diagnose.sh > network_report.txt

set -e

echo "==== NETWORK DIAGNOSTICS REPORT ===="

# Hostname and date
echo "Hostname: $(hostname)"
echo "Date: $(date)"

# Network interfaces and IPs
echo -e "\n--- Network Interfaces ---"
ip addr show

# Routing table
echo -e "\n--- Routing Table ---"
ip route show

# DNS configuration
echo -e "\n--- DNS Configuration ---"
cat /etc/resolv.conf

# UFW status
echo -e "\n--- UFW Status ---"
ufw status verbose || echo "UFW not installed or not running."

# iptables rules
echo -e "\n--- iptables Rules ---"
iptables -L -n -v

# Docker network status
echo -e "\n--- Docker Networks ---"
docker network ls
docker network inspect bridge || true

# Active listening ports
echo -e "\n--- Listening Ports ---"
ss -tulnp

# System logs for network changes
echo -e "\n--- Recent Network-Related System Logs ---"
if command -v journalctl >/dev/null 2>&1; then
  journalctl -u NetworkManager -u docker -u systemd-networkd --since "1 hour ago" | tail -n 100
else
  echo "journalctl command not available"
fi

# Check for network changes in dmesg
echo -e "\n--- dmesg Network Events ---"
dmesg | grep -i network | tail -n 20

# Docker container status
echo -e "\n--- Docker Containers ---"
docker ps -a

echo -e "\n==== END OF REPORT ===="
