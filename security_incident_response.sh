#!/bin/bash
# Automated Security Incident Response Script
# Automatically handles common security lockout scenarios

LOG_FILE="/var/log/security_incident_response.log"
BACKUP_DIR="/root/incident_backups"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

create_backup() {
    local backup_subdir="$BACKUP_DIR/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_subdir"
    
    # Backup critical configs
    cp /etc/ssh/sshd_config "$backup_subdir/" 2>/dev/null || true
    cp /etc/fail2ban/jail.local "$backup_subdir/" 2>/dev/null || true
    ufw status > "$backup_subdir/ufw_status.txt" 2>/dev/null || true
    iptables -L -n > "$backup_subdir/iptables_rules.txt" 2>/dev/null || true
    
    echo "$backup_subdir"
}

check_ssh_access() {
    log_message "Checking SSH accessibility..."
    
    # Test SSH config
    if ! sshd -t; then
        log_message "ERROR: SSH configuration is invalid"
        return 1
    fi
    
    # Check if SSH service is running
    if ! systemctl is-active ssh >/dev/null; then
        log_message "ERROR: SSH service is not running"
        return 1
    fi
    
    # Check if emergency users exist and can login
    for user in emergency backup; do
        if ! id "$user" >/dev/null 2>&1; then
            log_message "WARNING: Emergency user $user does not exist"
            return 1
        fi
    done
    
    log_message "SSH access check passed"
    return 0
}

restore_emergency_access() {
    log_message "=== EMERGENCY ACCESS RESTORATION INITIATED ==="
    
    local backup_dir=$(create_backup)
    log_message "Created backup in: $backup_dir"
    
    # Stop potentially blocking services
    log_message "Stopping security services..."
    systemctl stop fail2ban 2>/dev/null || true
    
    # Unban all IPs
    log_message "Unbanning all IPs from fail2ban..."
    fail2ban-client unban --all 2>/dev/null || true
    
    # Ensure UFW allows SSH
    log_message "Ensuring UFW allows SSH..."
    ufw allow 22/tcp 2>/dev/null || true
    
    # Fix SSH configuration
    log_message "Fixing SSH configuration..."
    
    # Ensure emergency users are in AllowUsers
    if grep -q "^AllowUsers" /etc/ssh/sshd_config; then
        sed -i 's/^AllowUsers.*$/AllowUsers cbwinslow emergency backup/' /etc/ssh/sshd_config
        log_message "Updated AllowUsers in SSH config"
    else
        echo "AllowUsers cbwinslow emergency backup" >> /etc/ssh/sshd_config
        log_message "Added AllowUsers to SSH config"
    fi
    
    # Ensure password authentication is enabled
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    
    # Test and restart SSH
    if sshd -t; then
        systemctl restart ssh
        log_message "SSH service restarted successfully"
    else
        log_message "ERROR: SSH config still invalid, restoring backup"
        cp "$backup_dir/sshd_config" /etc/ssh/sshd_config
        systemctl restart ssh
    fi
    
    # Create emergency users if they don't exist
    for user in emergency backup; do
        if ! id "$user" >/dev/null 2>&1; then
            log_message "Creating emergency user: $user"
            useradd -m -s /bin/bash "$user"
            echo "$user:${user}123" | chpasswd
            usermod -aG sudo "$user"
        fi
    done
    
    log_message "=== EMERGENCY ACCESS RESTORATION COMPLETED ==="
    log_message "Available accounts: cbwinslow, emergency:emergency123, backup:backup123"
}

monitor_failed_logins() {
    log_message "Monitoring failed login attempts..."
    
    # Count recent failed attempts
    local failed_count=$(grep "Failed password" /var/log/auth.log | grep "$(date '+%b %d')" | wc -l)
    
    if [ "$failed_count" -gt 10 ]; then
        log_message "WARNING: High number of failed login attempts today: $failed_count"
        
        # Get top attacking IPs
        local top_attackers=$(grep "Failed password" /var/log/auth.log | grep "$(date '+%b %d')" | awk '{print $11}' | sort | uniq -c | sort -nr | head -5)
        log_message "Top attacking IPs:\n$top_attackers"
        
        # Check if any emergency users are being attacked
        local emergency_attacks=$(grep "Failed password.*emergency\|Failed password.*backup" /var/log/auth.log | grep "$(date '+%b %d')" | wc -l)
        if [ "$emergency_attacks" -gt 0 ]; then
            log_message "CRITICAL: Emergency accounts are under attack! Consider changing passwords."
        fi
    fi
}

audit_security_status() {
    log_message "=== SECURITY STATUS AUDIT ==="
    
    # Check SSH
    if check_ssh_access; then
        log_message "✅ SSH access: OK"
    else
        log_message "❌ SSH access: ISSUES DETECTED"
    fi
    
    # Check UFW
    if ufw status | grep -q "Status: active"; then
        log_message "✅ UFW firewall: Active"
    else
        log_message "⚠️  UFW firewall: Inactive"
    fi
    
    # Check fail2ban
    if systemctl is-active fail2ban >/dev/null; then
        log_message "✅ fail2ban: Running"
        local banned_count=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $4}' || echo "0")
        log_message "Currently banned IPs: $banned_count"
    else
        log_message "⚠️  fail2ban: Not running"
    fi
    
    # Check for suspicious activity
    monitor_failed_logins
    
    # Check system resources
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    log_message "System load: $load_avg"
    
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        log_message "⚠️  Disk usage high: ${disk_usage}%"
    else
        log_message "✅ Disk usage: ${disk_usage}%"
    fi
    
    log_message "=== AUDIT COMPLETED ==="
}

# Main script logic
case "${1:-audit}" in
    "restore"|"emergency")
        restore_emergency_access
        ;;
    "audit"|"check")
        audit_security_status
        ;;
    "monitor")
        monitor_failed_logins
        ;;
    *)
        echo "Usage: $0 {restore|emergency|audit|check|monitor}"
        echo ""
        echo "Commands:"
        echo "  restore/emergency - Restore emergency SSH access"
        echo "  audit/check      - Run security status audit"
        echo "  monitor          - Monitor failed login attempts"
        echo ""
        echo "Default: audit"
        exit 1
        ;;
esac
