# Web Server Quick Start Guide

## 🚀 Your Server Setup

Your Hetzner server is now configured with:

### ✅ Security Features
- **Primary User**: `cbwinslow` (with sudo privileges)
- **SSH Hardening**: Secure configuration, emergency access maintained
- **Firewall**: UFW configured for web traffic (ports 22, 80, 443)
- **Intrusion Prevention**: fail2ban protecting against brute force
- **Monitoring**: Real-time security dashboard and automated checks

### ✅ Web Server Ready
- **Nginx**: Installed and configured for web hosting
- **SSL Ready**: Use `sudo certbot --nginx -d yourdomain.com`
- **Web Root**: `/var/www/html/` (owned by cbwinslow)
- **Welcome Page**: Available at `http://YOUR_IP`

## 🔑 Access Information

### SSH Access
```bash
ssh cbwinslow@YOUR_SERVER_IP
# Password: cbwinslow123
```

### Emergency Access (if needed)
```bash
ssh emergency@YOUR_SERVER_IP
# Password: emergency123
```

## 🛠️ Next Steps

### 1. Install Additional Programs
```bash
sudo ./recommended_programs.sh
```
This installs:
- **VS Code Server** (browser-based VS Code)
- **Database Management** (phpMyAdmin, pgAdmin)
- **Monitoring Tools** (htop, netdata, glances)
- **Security Scanners** (lynis, rkhunter)
- **Performance Tools** (Redis, Memcached)
- **Backup Solutions** and more!

### 2. Setup SSL Certificate
```bash
sudo certbot --nginx -d yourdomain.com
```

### 3. Deploy Your Application
```bash
# Upload files to web directory
cd /var/www/html/
# Your files go here
```

## 📊 Monitoring Commands

### Security Status
```bash
sudo /usr/local/bin/security_dashboard.sh
```

### Quick Security Check
```bash
sudo /usr/local/bin/quick_security_check.sh
```

### Continuous Monitoring
```bash
sudo /usr/local/bin/security_dashboard.sh --monitor
```

### System Status
```bash
# Check all services
sudo systemctl status nginx mariadb php*-fpm

# Check firewall
sudo ufw status verbose

# Check fail2ban
sudo fail2ban-client status
```

## 🌐 Web Services Access

After installing recommended programs, you'll have access to:

- **Your Website**: `http://YOUR_IP`
- **VS Code Server**: `http://YOUR_IP:8080`
- **Netdata Monitoring**: `http://YOUR_IP:19999`
- **phpMyAdmin**: `http://YOUR_IP/phpmyadmin`

## 🔒 Security Best Practices

### Regular Maintenance
1. **Update System Weekly**:
   ```bash
   sudo apt update && sudo apt upgrade
   ```

2. **Run Security Scans**:
   ```bash
   sudo lynis audit system
   ```

3. **Check Logs**:
   ```bash
   sudo tail -f /var/log/auth.log  # SSH attempts
   sudo tail -f /var/log/nginx/access.log  # Web access
   ```

### Backup Your Data
```bash
# Use the backup template
./backup_template.sh

# Or create custom backups
sudo tar -czf backup_$(date +%Y%m%d).tar.gz /var/www/html /home/cbwinslow
```

## 🆘 Emergency Procedures

### If Locked Out
1. Access Hetzner rescue mode
2. Run the rescue script: `./rescue_restore_access.sh`
3. Emergency users are always available

### If Services Down
```bash
# Restart web server
sudo systemctl restart nginx

# Check service status
sudo systemctl status nginx
sudo systemctl status ssh
```

## 📚 Useful Aliases

The `cbwinslow` user has these helpful aliases:
```bash
nginx-reload    # Reload nginx configuration
nginx-test      # Test nginx configuration
security-check  # Run quick security check
www            # Go to /var/www/html
logs           # View nginx error logs
```

## 🎯 Development Tips

### PHP Development
- PHP-FPM is configured and ready
- Upload files to `/var/www/html/`
- Nginx automatically serves PHP files

### Node.js Applications
- Install Node.js via recommended_programs.sh
- Use PM2 for process management
- Configure nginx as reverse proxy

### Database Applications
- MariaDB/MySQL and PostgreSQL available
- Web interfaces via phpMyAdmin/pgAdmin
- Secure by default, configure as needed

## 🎉 You're Ready!

Your server is now:
- ✅ Secured with industry best practices
- ✅ Ready for web development
- ✅ Monitored with automated tools
- ✅ Equipped with emergency access
- ✅ Prepared for SSL certificates
- ✅ Set up for easy maintenance

Deploy your applications and enjoy your secure, professional web server!
