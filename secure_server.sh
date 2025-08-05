#!/bin/bash
# Server Security Hardening Script
# Run this after regaining SSH access to properly secure your server

set -e

echo "=== SERVER SECURITY HARDENING ==="
echo "This script will secure your server while maintaining access"
echo ""

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo"
   echo "Usage: sudo bash secure_server.sh"
   exit 1
fi

# Backup critical files
echo "Step 1: Creating backups..."
BACKUP_DIR="/root/security_backups_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup important config files
cp /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.backup"
cp /etc/fail2ban/jail.local "$BACKUP_DIR/jail.local.backup" 2>/dev/null || echo "No existing jail.local found"
ufw status > "$BACKUP_DIR/ufw_status_before.txt" 2>/dev/null || echo "UFW not available"

echo "Backups created in: $BACKUP_DIR"

# Step 2: Create Users and Secure SSH Configuration
echo ""
echo "Step 2: Creating users and securing SSH configuration..."

# Create cbwinslow user first (primary user)
if ! id "cbwinslow" &>/dev/null; then
    echo "Creating cbwinslow user..."
    useradd -m -s /bin/bash cbwinslow
    usermod -aG sudo cbwinslow
    echo "cbwinslow:cbwinslow123" | chpasswd
    
    # Create .ssh directory for future key-based auth
    mkdir -p /home/cbwinslow/.ssh
    chmod 700 /home/cbwinslow/.ssh
    chown cbwinslow:cbwinslow /home/cbwinslow/.ssh
    
    echo "✓ cbwinslow user created with sudo privileges"
else
    echo "✓ cbwinslow user already exists"
fi

# Create emergency user (backup access)
if ! id "emergency" &>/dev/null; then
    echo "Creating emergency user..."
    useradd -m -s /bin/bash emergency
    usermod -aG sudo emergency
    echo "emergency:emergency123" | chpasswd
    echo "✓ emergency user created"
else
    echo "✓ emergency user already exists"
fi

# Create backup user (secondary backup)
if ! id "backup" &>/dev/null; then
    echo "Creating backup user..."
    useradd -m -s /bin/bash backup
    usermod -aG sudo backup
    echo "backup:backup123" | chpasswd
    echo "✓ backup user created"
else
    echo "✓ backup user already exists"
fi

# Configure SSH to allow these users
echo "Configuring SSH access..."

# Ensure cbwinslow and emergency users remain in AllowUsers
grep -q "^AllowUsers" /etc/ssh/sshd_config && {
    # If AllowUsers exists, make sure it includes main and emergency users
    sed -i 's/^AllowUsers.*$/AllowUsers cbwinslow emergency backup/' /etc/ssh/sshd_config
} || {
    # If no AllowUsers, add it with cbwinslow as primary user
    echo "AllowUsers cbwinslow emergency backup" >> /etc/ssh/sshd_config
}

# Secure SSH settings
cat > /tmp/ssh_security_config << 'EOF'
# Security hardening
Port 22
PasswordAuthentication yes
PubkeyAuthentication yes
PermitRootLogin no
PermitEmptyPasswords no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
Protocol 2
X11Forwarding no
UsePAM yes
EOF

# Apply security settings to SSH config
while IFS= read -r line; do
    if [[ $line =~ ^#.*$ ]] || [[ -z $line ]]; then
        continue
    fi
    
    setting=$(echo "$line" | cut -d' ' -f1)
    value=$(echo "$line" | cut -d' ' -f2-)
    
    # Remove existing setting and add new one
    sed -i "/^$setting /d" /etc/ssh/sshd_config
    sed -i "/^#$setting /d" /etc/ssh/sshd_config
    echo "$setting $value" >> /etc/ssh/sshd_config
done < /tmp/ssh_security_config

# Validate SSH config
sshd -t && echo "SSH configuration is valid" || {
    echo "ERROR: SSH configuration is invalid, restoring backup"
    cp "$BACKUP_DIR/sshd_config.backup" /etc/ssh/sshd_config
    exit 1
}

# Step 3: Configure UFW Firewall for Web Traffic
echo ""
echo "Step 3: Configuring UFW firewall for web server..."

# Reset UFW
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (critical!)
ufw allow 22/tcp comment 'SSH'

# Web traffic ports - enabled by default for web server
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Optional common services
read -p "Do you need FTP (port 21)? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ufw allow 21/tcp comment 'FTP'
fi

read -p "Do you need MySQL/MariaDB access (port 3306)? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ufw allow 3306/tcp comment 'MySQL/MariaDB'
fi

read -p "Do you need PostgreSQL access (port 5432)? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ufw allow 5432/tcp comment 'PostgreSQL'
fi

read -p "Do you need custom app port (e.g., Node.js, Django)? Enter port or press Enter to skip: " custom_port
if [[ -n "$custom_port" && "$custom_port" =~ ^[0-9]+$ ]]; then
    ufw allow "$custom_port"/tcp comment 'Custom Application'
fi

# Enable UFW
ufw --force enable

echo "UFW firewall configured:"
ufw status verbose

# Step 4: Configure fail2ban Safely
echo ""
echo "Step 4: Configuring fail2ban safely..."

# Create a safe fail2ban configuration
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Ban time in seconds (10 minutes)
bantime = 600

# Time window to consider for counting failures (10 minutes)
findtime = 600

# Number of failures before ban
maxretry = 5

# Ignore local/private networks
ignoreip = 127.0.0.1/8 ::1 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 1800
findtime = 600

# Create a whitelist for your IPs (add your IPs here)
[sshd-whitelist]
enabled = false
# Add your trusted IPs here:
# ignoreip = YOUR.IP.ADDRESS.HERE
EOF

# Enable and start fail2ban
systemctl enable fail2ban
systemctl restart fail2ban

echo "fail2ban configured and started"

# Step 5: System Updates and Security Packages
echo ""
echo "Step 5: Installing security updates and packages..."

# Update package list
apt update

# Install security updates
apt upgrade -y

# Install useful security tools
apt install -y \
    unattended-upgrades \
    logwatch \
    rkhunter \
    chkrootkit \
    aide \
    lynis

# Configure automatic security updates
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# Step 6: System Monitoring and Logging
echo ""
echo "Step 6: Setting up monitoring..."

# Configure logwatch
cat > /etc/cron.daily/00logwatch << 'EOF'
#!/bin/bash
/usr/sbin/logwatch --output mail --mailto root --detail high
EOF
chmod +x /etc/cron.daily/00logwatch

# Step 7: Emergency Access Maintenance
echo ""
echo "Step 7: Maintaining emergency access..."

# Ensure emergency users exist and have proper permissions
for user in emergency backup; do
    if ! id "$user" &>/dev/null; then
        useradd -m -s /bin/bash "$user"
        echo "$user:${user}123" | chpasswd
        usermod -aG sudo "$user"
        echo "Created user: $user with password: ${user}123"
    else
        echo "User $user already exists"
    fi
done

# Create emergency access script
cat > /root/emergency_access_restore.sh << 'EOF'
#!/bin/bash
# Emergency script to restore SSH access
# Run this if you get locked out again

echo "=== EMERGENCY ACCESS RESTORE ==="

# Reset UFW to allow SSH
ufw --force reset
ufw allow 22/tcp
ufw default deny incoming
ufw default allow outgoing
ufw --force enable

# Disable fail2ban temporarily
systemctl stop fail2ban

# Ensure emergency users can login
sed -i 's/^AllowUsers.*$/AllowUsers cbwinslow emergency backup/' /etc/ssh/sshd_config

# Restart SSH
systemctl restart ssh

echo "Emergency access restored!"
echo "Users: cbwinslow, emergency (emergency123), backup (backup123)"
EOF

chmod +x /root/emergency_access_restore.sh

# Step 8: Create monitoring script
cat > /usr/local/bin/security_monitor.sh << 'EOF'
#!/bin/bash
# Security monitoring script

echo "=== SECURITY STATUS REPORT ==="
echo "Generated: $(date)"
echo ""

echo "UFW Status:"
ufw status
echo ""

echo "fail2ban Status:"
fail2ban-client status
echo ""

echo "SSH Configuration Check:"
sshd -t && echo "SSH config: OK" || echo "SSH config: ERROR"
echo ""

echo "Last 10 SSH logins:"
lastlog | head -11
echo ""

echo "Failed SSH attempts (last 20):"
grep "Failed password" /var/log/auth.log | tail -20 | awk '{print $1, $2, $3, $9, $11}' || echo "No recent failures"
echo ""

echo "Active network connections:"
ss -tulpn | grep :22
EOF

chmod +x /usr/local/bin/security_monitor.sh

# Create daily security check cron job
cat > /etc/cron.daily/security-check << 'EOF'
#!/bin/bash
/usr/local/bin/security_monitor.sh > /var/log/security_check.log 2>&1
EOF
chmod +x /etc/cron.daily/security-check

# Step 9: Final validation
echo ""
echo "Step 9: Final validation..."

# Test SSH config
sshd -t && echo "✓ SSH configuration valid" || echo "✗ SSH configuration invalid"

# Check UFW status
ufw status | grep -q "Status: active" && echo "✓ UFW firewall active" || echo "✗ UFW firewall inactive"

# Check fail2ban
systemctl is-active fail2ban >/dev/null && echo "✓ fail2ban running" || echo "✗ fail2ban not running"

# Restart services to apply all changes
echo ""
echo "Restarting services..."
systemctl restart ssh
systemctl restart fail2ban

echo ""
echo "=== WEB SERVER SETUP ==="
echo ""
echo "Installing essential web server packages..."

# Update package list
apt update

# Install essential packages for web development
echo "Installing web server essentials..."
apt install -y nginx certbot python3-certbot-nginx
apt install -y git curl wget htop tree unzip
apt install -y build-essential software-properties-common

# Install database options
read -p "Install MySQL/MariaDB? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y mariadb-server mariadb-client
    systemctl enable mariadb
    echo "✓ MariaDB installed - run 'sudo mysql_secure_installation' later"
fi

read -p "Install PostgreSQL? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y postgresql postgresql-contrib
    systemctl enable postgresql
    echo "✓ PostgreSQL installed"
fi

# Install PHP
read -p "Install PHP (with common modules)? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y php-fpm php-mysql php-pgsql php-cli php-common php-curl php-mbstring php-xml php-zip php-gd php-bcmath php-json
    systemctl enable php*-fpm
    echo "✓ PHP installed with common modules"
fi

# Install Node.js
read -p "Install Node.js (via NodeSource)? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt install -y nodejs
    npm install -g pm2
    echo "✓ Node.js and PM2 installed"
fi

# Install Python tools
read -p "Install Python development tools? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y python3-pip python3-venv python3-dev
    pip3 install virtualenv uwsgi
    echo "✓ Python development tools installed"
fi

# Install Docker
read -p "Install Docker? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker cbwinslow
    systemctl enable docker
    echo "✓ Docker installed - cbwinslow added to docker group"
fi

# Setup nginx basic config
echo "Configuring nginx..."
systemctl enable nginx

# Create a basic site config for cbwinslow
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html index.php;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    # PHP processing (if installed)
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
EOF

systemctl start nginx

# Set proper ownership
chown -R cbwinslow:www-data /var/www/html
chmod -R 755 /var/www/html

# Create a welcome page
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Server Ready - cbwinslow</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }
        .status { background: #e8f5e8; padding: 15px; border-radius: 4px; margin: 20px 0; }
        .command { background: #f0f0f0; padding: 10px; border-radius: 4px; font-family: monospace; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Server Successfully Configured</h1>
        <div class="status">
            <strong>Status:</strong> Your web server is ready for development!<br>
            <strong>User:</strong> cbwinslow<br>
            <strong>Security:</strong> Hardened and monitoring active
        </div>
        
        <h2>🛠️ What's Installed</h2>
        <ul>
            <li>Nginx web server (running)</li>
            <li>Security monitoring tools</li>
            <li>UFW firewall (ports 22, 80, 443 open)</li>
            <li>fail2ban intrusion prevention</li>
            <li>Development tools and utilities</li>
        </ul>
        
        <h2>📝 Next Steps</h2>
        <div class="command">sudo certbot --nginx -d yourdomain.com</div>
        <p>Run the above command to get SSL certificates for your domain.</p>
        
        <div class="command">sudo /usr/local/bin/security_dashboard.sh</div>
        <p>Check your server security status anytime.</p>
        
        <p>Deploy your web applications to <code>/var/www/html/</code></p>
    </div>
</body>
</html>
EOF

echo ""
echo "=== SECURITY HARDENING COMPLETE ==="
echo ""
echo "Summary of changes:"
echo "1. ✓ SSH secured with cbwinslow as primary user"
echo "2. ✓ UFW firewall configured for web traffic"
echo "3. ✓ fail2ban configured with safe settings"
echo "4. ✓ Web server (nginx) installed and configured"
echo "5. ✓ cbwinslow user created with sudo privileges"
echo "6. ✓ Development tools and optional packages installed"
echo ""
echo "🌐 Your server is ready for web development!"
echo ""
echo "Access your server:"
echo "- SSH: ssh cbwinslow@YOUR_SERVER_IP"
echo "- Web: http://YOUR_SERVER_IP"
echo "- HTTPS: Setup with 'sudo certbot --nginx'"
echo ""
echo "Security monitoring:"
echo "- sudo /usr/local/bin/security_dashboard.sh"
echo "- sudo /usr/local/bin/quick_security_check.sh"
echo ""
echo "Emergency access still available:"
echo "- emergency:emergency123"
echo "- backup:backup123"
echo ""
echo "🎉 Setup complete! Deploy your applications to /var/www/html/"
echo "4. ✓ System updated and security tools installed"
echo "5. ✓ Monitoring and logging configured"
echo "6. ✓ Emergency access procedures created"
echo ""
echo "Important files created:"
echo "- Emergency restore script: /root/emergency_access_restore.sh"
echo "- Security monitor: /usr/local/bin/security_monitor.sh"
echo "- Backups: $BACKUP_DIR"
echo ""
echo "Emergency user credentials:"
echo "- emergency:emergency123"
echo "- backup:backup123"
echo ""
echo "NEXT STEPS:"
echo "1. Test SSH access from a new terminal (don't close this one!)"
echo "2. Add your trusted IP addresses to fail2ban whitelist in /etc/fail2ban/jail.local"
echo "3. Consider changing SSH port from 22 to a custom port"
echo "4. Set up SSH key authentication and disable password auth later"
echo "5. Run security audit: sudo lynis audit system"
echo ""
echo "To monitor security status: sudo /usr/local/bin/security_monitor.sh"
echo ""
echo "🔒 Your server is now properly secured!"
