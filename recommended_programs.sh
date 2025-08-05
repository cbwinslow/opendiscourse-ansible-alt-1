#!/bin/bash
# Recommended Programs and Tools for Web Development Server
# Run this after basic server setup to install additional useful tools

set -e

echo "=== RECOMMENDED PROGRAMS FOR WEB DEVELOPMENT ==="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script should be run with sudo"
   echo "Usage: sudo bash recommended_programs.sh"
   exit 1
fi

echo "This script will install additional useful programs for web development."
echo "You can skip any category you don't need."
echo ""

# Update package list
apt update

# Development Tools
echo "=== DEVELOPMENT TOOLS ==="
read -p "Install advanced development tools? (vim, nano, code-server, zsh) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y vim nano zsh
    
    # Install oh-my-zsh for cbwinslow user
    sudo -u cbwinslow sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Install code-server (VS Code in browser)
    curl -fsSL https://code-server.dev/install.sh | sh
    systemctl enable --now code-server@cbwinslow
    
    echo "✓ Development tools installed"
    echo "  - VS Code available at http://YOUR_IP:8080"
    echo "  - Default password in ~/.config/code-server/config.yaml"
fi

# Database Management
echo ""
echo "=== DATABASE MANAGEMENT ==="
read -p "Install database management tools? (phpMyAdmin, pgAdmin) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Install phpMyAdmin
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/app-password-confirm password admin123" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password admin123" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/app-pass password admin123" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect nginx" | debconf-set-selections
    
    apt install -y phpmyadmin
    
    # Configure nginx for phpMyAdmin
    cat >> /etc/nginx/sites-available/default << 'EOF'

# phpMyAdmin configuration
location /phpmyadmin {
    root /usr/share/;
    index index.php index.html index.htm;
    location ~ ^/phpmyadmin/(.+\.php)$ {
        try_files $uri =404;
        root /usr/share/;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
    }
    location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
        root /usr/share/;
    }
}
EOF
    
    systemctl reload nginx
    echo "✓ phpMyAdmin installed - Access at http://YOUR_IP/phpmyadmin"
fi

# Monitoring Tools
echo ""
echo "=== MONITORING & ANALYTICS ==="
read -p "Install monitoring tools? (htop, iotop, netdata, glances) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y htop iotop glances
    
    # Install netdata for real-time monitoring
    bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait
    
    echo "✓ Monitoring tools installed"
    echo "  - htop: Advanced process viewer"
    echo "  - iotop: Disk I/O monitor"
    echo "  - glances: System monitor"
    echo "  - netdata: Real-time monitoring at http://YOUR_IP:19999"
fi

# Security Tools
echo ""
echo "=== ADDITIONAL SECURITY TOOLS ==="
read -p "Install security scanning tools? (lynis, rkhunter, chkrootkit) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y lynis rkhunter chkrootkit
    
    # Configure rkhunter
    rkhunter --update
    rkhunter --propupd
    
    echo "✓ Security tools installed"
    echo "  - lynis: Security auditing tool"
    echo "  - rkhunter: Rootkit scanner"
    echo "  - chkrootkit: Rootkit detector"
fi

# Backup Tools
echo ""
echo "=== BACKUP & FILE MANAGEMENT ==="
read -p "Install backup and file management tools? (rsync, duplicity, mc) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y rsync duplicity mc ncdu
    
    # Create backup script template
    cat > /home/cbwinslow/backup_template.sh << 'EOF'
#!/bin/bash
# Backup script template
# Customize paths and destinations as needed

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup"
SOURCE_DIRS="/var/www/html /home/cbwinslow /etc"

mkdir -p $BACKUP_DIR

# Simple tar backup
tar -czf "$BACKUP_DIR/backup_$BACKUP_DATE.tar.gz" $SOURCE_DIRS

# Keep only last 7 backups
find $BACKUP_DIR -name "backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed: backup_$BACKUP_DATE.tar.gz"
EOF
    
    chown cbwinslow:cbwinslow /home/cbwinslow/backup_template.sh
    chmod +x /home/cbwinslow/backup_template.sh
    
    echo "✓ Backup tools installed"
    echo "  - rsync: File synchronization"
    echo "  - duplicity: Encrypted backups"
    echo "  - mc: File manager"
    echo "  - Backup template: /home/cbwinslow/backup_template.sh"
fi

# Performance Tools
echo ""
echo "=== PERFORMANCE OPTIMIZATION ==="
read -p "Install performance optimization tools? (redis, memcached, varnish) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y redis-server memcached varnish
    
    systemctl enable redis-server
    systemctl enable memcached
    
    echo "✓ Performance tools installed"
    echo "  - Redis: In-memory data store"
    echo "  - Memcached: Memory caching system"
    echo "  - Varnish: HTTP accelerator"
fi

# SSL/TLS Tools
echo ""
echo "=== SSL/TLS & DOMAIN TOOLS ==="
read -p "Install SSL and domain management tools? (certbot extras, openssl tools) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y python3-certbot-apache python3-certbot-dns-cloudflare
    apt install -y openssl ca-certificates
    apt install -y whois dnsutils
    
    echo "✓ SSL/TLS tools installed"
    echo "  - Certbot with DNS plugins"
    echo "  - OpenSSL tools"
    echo "  - DNS utilities (dig, nslookup, whois)"
fi

# Content Management
echo ""
echo "=== CONTENT MANAGEMENT ==="
read -p "Install content management tools? (imagemagick, ffmpeg, pandoc) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y imagemagick ffmpeg pandoc
    apt install -y ghostscript poppler-utils
    
    echo "✓ Content management tools installed"
    echo "  - ImageMagick: Image processing"
    echo "  - FFmpeg: Video/audio processing"
    echo "  - Pandoc: Document conversion"
    echo "  - PDF tools"
fi

# Create a useful aliases file for cbwinslow
echo ""
echo "Setting up useful aliases and functions..."
cat >> /home/cbwinslow/.bashrc << 'EOF'

# Useful aliases for web development
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias h='history'
alias c='clear'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'
alias top='htop'
alias nano='nano -w'
alias grep='grep --color=auto'

# Web server shortcuts
alias nginx-test='sudo nginx -t'
alias nginx-reload='sudo nginx -s reload'
alias nginx-restart='sudo systemctl restart nginx'
alias logs='sudo tail -f /var/log/nginx/error.log'
alias access-logs='sudo tail -f /var/log/nginx/access.log'
alias www='cd /var/www/html'

# Security shortcuts
alias security-check='sudo /usr/local/bin/quick_security_check.sh'
alias security-dashboard='sudo /usr/local/bin/security_dashboard.sh'
alias ufw-status='sudo ufw status verbose'
alias fail2ban-status='sudo fail2ban-client status'

# System shortcuts
alias services='sudo systemctl status nginx mariadb php*-fpm redis-server'
alias disk-usage='ncdu /'
alias network='ss -tulpn'
alias processes='ps aux | head -20'

# Backup function
backup-site() {
    if [ -z "$1" ]; then
        echo "Usage: backup-site <description>"
        return 1
    fi
    DATE=$(date +%Y%m%d_%H%M%S)
    sudo tar -czf "/backup/site_${1}_${DATE}.tar.gz" /var/www/html
    echo "Site backed up to: /backup/site_${1}_${DATE}.tar.gz"
}

# Quick security scan
security-scan() {
    echo "=== Quick Security Scan ==="
    sudo lynis audit system --quick
}
EOF

chown cbwinslow:cbwinslow /home/cbwinslow/.bashrc

echo ""
echo "=== INSTALLATION COMPLETE ==="
echo ""
echo "🎉 Additional programs installed successfully!"
echo ""
echo "Summary of what's available:"
echo "- Development: VS Code Server, advanced editors"
echo "- Monitoring: Real-time dashboards and system monitors"
echo "- Security: Scanning and audit tools"
echo "- Performance: Caching and optimization"
echo "- Backup: Automated backup solutions"
echo "- Content: Media processing tools"
echo ""
echo "Useful commands added to cbwinslow user:"
echo "- nginx-test, nginx-reload, nginx-restart"
echo "- security-check, security-dashboard"
echo "- backup-site <description>"
echo "- security-scan"
echo ""
echo "Access your tools:"
echo "- VS Code: http://YOUR_IP:8080"
echo "- Netdata: http://YOUR_IP:19999"
echo "- phpMyAdmin: http://YOUR_IP/phpmyadmin"
echo ""
echo "Run 'source ~/.bashrc' as cbwinslow to load new aliases!"
