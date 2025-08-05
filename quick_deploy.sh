#!/bin/bash
# Quick deployment to fresh Hetzner server
# Usage: ./quick_deploy.sh YOUR_SERVER_IP

if [ -z "$1" ]; then
    echo "Usage: ./quick_deploy.sh YOUR_SERVER_IP"
    echo "Example: ./quick_deploy.sh 95.217.106.172"
    exit 1
fi

SERVER_IP=$1

echo "🚀 Quick deploying to fresh OS at $SERVER_IP..."
echo ""

# Make all scripts executable
chmod +x *.sh

# Run the deployment for fresh OS (uses root)
./deploy_security.sh << EOF
$SERVER_IP
y
root
EOF

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "Next steps:"
echo "1. ssh cbwinslow@$SERVER_IP (password: cbwinslow123)"
echo "2. sudo ./recommended_programs.sh (install additional tools)"
echo "3. sudo certbot --nginx -d yourdomain.com (setup SSL)"
echo ""
echo "Emergency access also available:"
echo "- ssh emergency@$SERVER_IP (password: emergency123)"
echo "- ssh backup@$SERVER_IP (password: backup123)"
echo ""
echo "Your server is ready for web development!"
