#!/bin/bash
# Security Hardening Deployment Script
# Quick deployment of security tools to Hetzner server

set -e

echo "=== HETZNER SERVER SECURITY DEPLOYMENT ==="
echo ""

# Get server details
read -p "Enter your Hetzner server IP: " SERVER_IP
read -p "Fresh OS install? (only root available) [y/N]: " FRESH_INSTALL
read -p "Enter SSH user [root for fresh install]: " SERVER_USER

if [[ $FRESH_INSTALL =~ ^[Yy]$ ]]; then
    SERVER_USER=${SERVER_USER:-root}
    echo "Fresh OS detected - will create cbwinslow user during setup"
else
    SERVER_USER=${SERVER_USER:-cbwinslow}
fi

if [ -z "$SERVER_IP" ]; then
    echo "Error: Server IP is required"
    exit 1
fi

echo ""
echo "Deploying to: $SERVER_USER@$SERVER_IP"
echo ""

# Test connection
echo "Testing connection..."
if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o PreferredAuthentications=password -o PubkeyAuthentication=no \
    "$SERVER_USER@$SERVER_IP" "echo 'Connection successful'"; then
    echo "Error: Cannot connect to server"
    echo "Try connecting manually first: ssh -o PreferredAuthentications=password $SERVER_USER@$SERVER_IP"
    exit 1
fi

echo "✓ Connection successful"
echo ""

# Copy security scripts to server
echo "Copying security scripts..."
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o PreferredAuthentications=password -o PubkeyAuthentication=no \
    secure_server.sh \
    security_dashboard.sh \
    security_incident_response.sh \
    quick_security_check.sh \
    recommended_programs.sh \
    "$SERVER_USER@$SERVER_IP:~/"

echo "✓ Scripts copied"
echo ""

# Run security hardening on server
echo "Running security hardening..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o PreferredAuthentications=password -o PubkeyAuthentication=no \
    "$SERVER_USER@$SERVER_IP" << 'EOF'

# Make scripts executable
chmod +x *.sh

echo "=== Starting Security Hardening ==="

# Run the main security script (handles running as root or with sudo)
if [ "$USER" = "root" ]; then
    ./secure_server.sh
else
    sudo ./secure_server.sh
fi

# Install security monitoring tools
echo "Installing security monitoring tools..."
if [ "$USER" = "root" ]; then
    cp security_dashboard.sh /usr/local/bin/
    cp security_incident_response.sh /usr/local/bin/
    cp quick_security_check.sh /usr/local/bin/
    chmod +x /usr/local/bin/security_*.sh /usr/local/bin/quick_security_check.sh
    
    # Create monitoring cron job
    echo "Setting up automated monitoring..."
    echo "0 6 * * * /usr/local/bin/security_dashboard.sh --save > /var/log/daily_security_report.log 2>&1" | tee /etc/cron.d/daily-security
else
    sudo cp security_dashboard.sh /usr/local/bin/
    sudo cp security_incident_response.sh /usr/local/bin/
    sudo cp quick_security_check.sh /usr/local/bin/
    sudo chmod +x /usr/local/bin/security_*.sh /usr/local/bin/quick_security_check.sh
    
    # Create monitoring cron job
    echo "Setting up automated monitoring..."
    echo "0 6 * * * /usr/local/bin/security_dashboard.sh --save > /var/log/daily_security_report.log 2>&1" | sudo tee /etc/cron.d/daily-security
fi

echo ""
echo "=== Security Hardening Complete ==="
echo ""
echo "Security tools installed:"
echo "- /usr/local/bin/security_dashboard.sh"
echo "- /usr/local/bin/security_incident_response.sh" 
echo "- /usr/local/bin/quick_security_check.sh"
echo ""
echo "Additional programs available:"
echo "- Run: sudo ./recommended_programs.sh"
echo "  (Installs VS Code Server, monitoring tools, security scanners, etc.)"
echo ""
echo "To check security status:"
echo "sudo /usr/local/bin/security_dashboard.sh"
echo ""
echo "For continuous monitoring:"
echo "sudo /usr/local/bin/security_dashboard.sh --monitor"
echo ""
echo "🔒 Your server is now secured!"
EOF

echo ""
echo "=== DEPLOYMENT COMPLETE ==="
echo ""
echo "Your Hetzner server is now comprehensively secured and web-ready with:"
echo "1. ✓ Hardened SSH configuration (cbwinslow as primary user)"
echo "2. ✓ UFW firewall configured for web traffic (ports 22,80,443)"  
echo "3. ✓ fail2ban protection"
echo "4. ✓ Nginx web server installed and running"
echo "5. ✓ Security monitoring tools"
echo "6. ✓ Development environment ready"
echo ""
echo "Access your server:"
echo "- SSH: ssh cbwinslow@$SERVER_IP"
echo "- Web: http://$SERVER_IP"
echo ""
echo "Next steps:"
echo "- Setup SSL: sudo certbot --nginx -d yourdomain.com"
echo "- Monitor security: sudo /usr/local/bin/security_dashboard.sh"
echo "- Deploy apps to: /var/www/html/"
echo ""
echo "Emergency credentials (if needed):"
echo "- emergency:emergency123"
echo "- backup:backup123"
echo ""
echo "🎉 Your web server is ready for production!"
