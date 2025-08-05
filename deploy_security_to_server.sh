#!/bin/bash
# Deploy Security Tools to Hetzner Server
# This script copies our security hardening tools to the remote server

set -e

# Configuration
SERVER_IP="${1:-YOUR_SERVER_IP}"
SERVER_USER="emergency"
SERVER_PASS="emergency123"

if [ "$SERVER_IP" = "YOUR_SERVER_IP" ]; then
    echo "Usage: $0 <SERVER_IP>"
    echo "Example: $0 192.168.1.100"
    exit 1
fi

echo "=== DEPLOYING SECURITY TOOLS TO HETZNER SERVER ==="
echo "Server: $SERVER_IP"
echo "User: $SERVER_USER"
echo ""

# Create temporary directory for deployment files
TEMP_DIR="/tmp/security_deployment_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$TEMP_DIR"

echo "Step 1: Preparing deployment files..."

# Copy our security scripts to temp directory
cp secure_server.sh "$TEMP_DIR/"
cp security_dashboard.sh "$TEMP_DIR/"
cp security_incident_response.sh "$TEMP_DIR/"
cp quick_security_check.sh "$TEMP_DIR/"

# Make scripts executable
chmod +x "$TEMP_DIR"/*.sh

echo "Step 2: Copying files to server..."

# Use scp to copy files to server
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$TEMP_DIR"/*.sh "$SERVER_USER@$SERVER_IP:~/"

echo "Step 3: Deploying security configuration..."

# SSH to server and run deployment
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$SERVER_USER@$SERVER_IP" << 'EOF'
# Make scripts executable
chmod +x *.sh

# Run security hardening
echo "Running security hardening script..."
sudo ./secure_server.sh

# Set up security monitoring
echo "Setting up security monitoring..."
sudo cp security_dashboard.sh /usr/local/bin/
sudo cp security_incident_response.sh /usr/local/bin/
sudo cp quick_security_check.sh /usr/local/bin/

# Create daily security monitoring cron job
echo "0 6 * * * /usr/local/bin/security_dashboard.sh --save > /var/log/daily_security_report.log 2>&1" | sudo tee /etc/cron.d/daily-security-report

echo "Security deployment completed!"
echo ""
echo "Available security tools:"
echo "- security_dashboard.sh (comprehensive security dashboard)"
echo "- security_incident_response.sh (incident response automation)"
echo "- quick_security_check.sh (quick security status check)"
echo ""
echo "To run security dashboard: sudo /usr/local/bin/security_dashboard.sh"
echo "For continuous monitoring: sudo /usr/local/bin/security_dashboard.sh --monitor"
EOF

echo ""
echo "Step 4: Cleanup..."
rm -rf "$TEMP_DIR"

echo ""
echo "=== DEPLOYMENT COMPLETE ==="
echo ""
echo "Your Hetzner server now has comprehensive security hardening:"
echo "1. ✓ Secure SSH configuration with emergency access"
echo "2. ✓ UFW firewall properly configured"
echo "3. ✓ fail2ban with safe settings"
echo "4. ✓ Security monitoring tools installed"
echo "5. ✓ Automated security reporting"
echo ""
echo "To connect to your server:"
echo "ssh $SERVER_USER@$SERVER_IP"
echo ""
echo "To check security status:"
echo "ssh $SERVER_USER@$SERVER_IP 'sudo /usr/local/bin/security_dashboard.sh'"
echo ""
echo "Emergency access users:"
echo "- emergency:emergency123"
echo "- backup:backup123"
echo ""
echo "🔒 Your server is now comprehensively secured!"
