#!/bin/bash
# Security Dashboard - Real-time server security monitoring
# Provides comprehensive overview of server security status

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
LOGFILE="/var/log/security-dashboard.log"
REPORT_DIR="/opt/security-reports"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Create necessary directories
mkdir -p "$REPORT_DIR"

# Logging function
log_message() {
    echo "[$DATE] $1" >> "$LOGFILE"
}

# Header function
print_header() {
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${CYAN}              SECURITY DASHBOARD - $(hostname)${NC}"
    echo -e "${CYAN}                    $DATE${NC}"
    echo -e "${CYAN}============================================================${NC}"
    echo ""
}

# System status check
check_system_status() {
    echo -e "${BLUE}=== SYSTEM STATUS ===${NC}"
    
    # Uptime
    echo -e "${CYAN}Uptime:${NC} $(uptime -p)"
    
    # Load average
    load=$(uptime | grep -oE 'load average: [0-9.,]+' | cut -d' ' -f3-)
    echo -e "${CYAN}Load Average:${NC} $load"
    
    # Memory usage
    memory_info=$(free -h | grep Mem)
    memory_used=$(echo $memory_info | awk '{print $3}')
    memory_total=$(echo $memory_info | awk '{print $2}')
    echo -e "${CYAN}Memory Usage:${NC} $memory_used / $memory_total"
    
    # Disk usage
    echo -e "${CYAN}Disk Usage:${NC}"
    df -h | grep -E '^/dev/' | while read line; do
        usage=$(echo $line | awk '{print $5}' | sed 's/%//')
        if [ "$usage" -gt 90 ]; then
            echo -e "  ${RED}$line${NC}"
        elif [ "$usage" -gt 75 ]; then
            echo -e "  ${YELLOW}$line${NC}"
        else
            echo -e "  ${GREEN}$line${NC}"
        fi
    done
    echo ""
}

# SSH security check
check_ssh_security() {
    echo -e "${BLUE}=== SSH SECURITY STATUS ===${NC}"
    
    # SSH service status
    if systemctl is-active --quiet ssh || systemctl is-active --quiet sshd; then
        echo -e "${GREEN}✓ SSH Service: Running${NC}"
    else
        echo -e "${RED}✗ SSH Service: Not Running${NC}"
        log_message "ALERT: SSH service is not running"
    fi
    
    # SSH port
    ssh_port=$(grep "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "22")
    echo -e "${CYAN}SSH Port:${NC} $ssh_port"
    
    # Root login status
    root_login=$(grep "^PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "unknown")
    if [ "$root_login" = "no" ]; then
        echo -e "${GREEN}✓ Root Login: Disabled${NC}"
    else
        echo -e "${YELLOW}⚠ Root Login: $root_login${NC}"
    fi
    
    # Password authentication
    pass_auth=$(grep "^PasswordAuthentication" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "unknown")
    echo -e "${CYAN}Password Auth:${NC} $pass_auth"
    
    # Allow/Deny users
    allow_users=$(grep "^AllowUsers" /etc/ssh/sshd_config 2>/dev/null | cut -d' ' -f2- || echo "none")
    echo -e "${CYAN}Allowed Users:${NC} $allow_users"
    
    # Recent SSH connections
    echo -e "${CYAN}Recent SSH Connections:${NC}"
    last -n 10 | grep -E "(ssh|pts)" | head -5 | while read line; do
        echo "  $line"
    done
    echo ""
}

# Firewall status
check_firewall_status() {
    echo -e "${BLUE}=== FIREWALL STATUS ===${NC}"
    
    # UFW status
    if command -v ufw >/dev/null 2>&1; then
        ufw_status=$(ufw status | head -1)
        if echo "$ufw_status" | grep -q "active"; then
            echo -e "${GREEN}✓ UFW: Active${NC}"
        else
            echo -e "${RED}✗ UFW: Inactive${NC}"
            log_message "ALERT: UFW firewall is inactive"
        fi
        
        echo -e "${CYAN}UFW Rules:${NC}"
        ufw status numbered | tail -n +4 | head -10
    else
        echo -e "${YELLOW}⚠ UFW: Not installed${NC}"
    fi
    
    # iptables rules count
    if command -v iptables >/dev/null 2>&1; then
        iptables_rules=$(iptables -L | grep -c "^ACCEPT\|^DROP\|^REJECT" || echo "0")
        echo -e "${CYAN}iptables Rules:${NC} $iptables_rules active rules"
    fi
    echo ""
}

# fail2ban status
check_fail2ban_status() {
    echo -e "${BLUE}=== FAIL2BAN STATUS ===${NC}"
    
    if systemctl is-active --quiet fail2ban; then
        echo -e "${GREEN}✓ fail2ban: Running${NC}"
        
        # Active jails
        echo -e "${CYAN}Active Jails:${NC}"
        fail2ban-client status | grep "Jail list:" | cut -d: -f2 | tr ',' '\n' | while read jail; do
            jail=$(echo $jail | xargs)
            if [ -n "$jail" ]; then
                banned=$(fail2ban-client status "$jail" 2>/dev/null | grep "Currently banned:" | awk '{print $3}' || echo "0")
                echo "  $jail: $banned banned IPs"
            fi
        done
        
        # Recent bans
        echo -e "${CYAN}Recent Bans (last 24h):${NC}"
        grep "$(date +%Y-%m-%d)" /var/log/fail2ban.log 2>/dev/null | grep "Ban " | tail -5 | while read line; do
            echo "  $line"
        done
    else
        echo -e "${RED}✗ fail2ban: Not Running${NC}"
        log_message "ALERT: fail2ban service is not running"
    fi
    echo ""
}

# Security events monitoring
check_security_events() {
    echo -e "${BLUE}=== SECURITY EVENTS ===${NC}"
    
    # Failed SSH attempts today
    failed_ssh=$(grep "$(date +%b\ %d)" /var/log/auth.log 2>/dev/null | grep -c "Failed password" || echo "0")
    if [ "$failed_ssh" -gt 20 ]; then
        echo -e "${RED}⚠ Failed SSH Attempts Today: $failed_ssh${NC}"
        log_message "HIGH: $failed_ssh failed SSH attempts today"
    elif [ "$failed_ssh" -gt 5 ]; then
        echo -e "${YELLOW}⚠ Failed SSH Attempts Today: $failed_ssh${NC}"
    else
        echo -e "${GREEN}✓ Failed SSH Attempts Today: $failed_ssh${NC}"
    fi
    
    # Successful SSH logins today
    successful_ssh=$(grep "$(date +%b\ %d)" /var/log/auth.log 2>/dev/null | grep -c "Accepted password\|Accepted publickey" || echo "0")
    echo -e "${CYAN}Successful SSH Logins Today:${NC} $successful_ssh"
    
    # sudo usage today
    sudo_usage=$(grep "$(date +%b\ %d)" /var/log/auth.log 2>/dev/null | grep -c "sudo:" || echo "0")
    echo -e "${CYAN}Sudo Commands Today:${NC} $sudo_usage"
    
    # System reboots
    last_reboot=$(last reboot | head -1 | awk '{print $5, $6, $7}')
    echo -e "${CYAN}Last Reboot:${NC} $last_reboot"
    
    # Process anomalies (high CPU processes)
    echo -e "${CYAN}Top CPU Processes:${NC}"
    ps aux --sort=-%cpu | head -6 | tail -5 | while read line; do
        cpu=$(echo $line | awk '{print $3}')
        if (( $(echo "$cpu > 50" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "  ${RED}$line${NC}"
        else
            echo "  $line"
        fi
    done
    echo ""
}

# Network connections
check_network_connections() {
    echo -e "${BLUE}=== NETWORK CONNECTIONS ===${NC}"
    
    # Listening ports
    echo -e "${CYAN}Listening Ports:${NC}"
    netstat -tlnp 2>/dev/null | grep LISTEN | head -10 | while read line; do
        port=$(echo $line | awk '{print $4}' | cut -d: -f2)
        if [ "$port" = "22" ] || [ "$port" = "80" ] || [ "$port" = "443" ]; then
            echo -e "  ${GREEN}$line${NC}"
        else
            echo "  $line"
        fi
    done
    
    # Active connections
    active_connections=$(netstat -tn 2>/dev/null | grep ESTABLISHED | wc -l)
    echo -e "${CYAN}Active Connections:${NC} $active_connections"
    
    # Unique IP connections
    unique_ips=$(netstat -tn 2>/dev/null | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort -u | wc -l)
    echo -e "${CYAN}Unique Connected IPs:${NC} $unique_ips"
    echo ""
}

# Emergency users check
check_emergency_users() {
    echo -e "${BLUE}=== EMERGENCY ACCESS ===${NC}"
    
    # Check if emergency users exist and have proper permissions
    for user in emergency backup; do
        if id "$user" >/dev/null 2>&1; then
            if groups "$user" | grep -q sudo; then
                echo -e "${GREEN}✓ Emergency user '$user': Exists with sudo access${NC}"
            else
                echo -e "${YELLOW}⚠ Emergency user '$user': Exists but no sudo access${NC}"
                log_message "WARNING: Emergency user $user has no sudo access"
            fi
        else
            echo -e "${RED}✗ Emergency user '$user': Does not exist${NC}"
            log_message "ALERT: Emergency user $user does not exist"
        fi
    done
    echo ""
}

# System updates check
check_system_updates() {
    echo -e "${BLUE}=== SYSTEM UPDATES ===${NC}"
    
    if command -v apt >/dev/null 2>&1; then
        # Check for available updates
        updates=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")
        security_updates=$(apt list --upgradable 2>/dev/null | grep -c security || echo "0")
        
        if [ "$security_updates" -gt 0 ]; then
            echo -e "${RED}⚠ Security Updates Available: $security_updates${NC}"
            log_message "ALERT: $security_updates security updates available"
        else
            echo -e "${GREEN}✓ No Security Updates Pending${NC}"
        fi
        
        echo -e "${CYAN}Total Updates Available:${NC} $updates"
        
        # Last update
        last_update=$(stat -c %y /var/log/apt/history.log 2>/dev/null | cut -d' ' -f1 || echo "unknown")
        echo -e "${CYAN}Last Update Check:${NC} $last_update"
    fi
    echo ""
}

# Generate summary
generate_summary() {
    echo -e "${BLUE}=== SECURITY SUMMARY ===${NC}"
    
    local issues=0
    local warnings=0
    
    # Check critical services
    if ! systemctl is-active --quiet ssh && ! systemctl is-active --quiet sshd; then
        ((issues++))
    fi
    
    if ! systemctl is-active --quiet fail2ban; then
        ((warnings++))
    fi
    
    if ! ufw status | grep -q "active"; then
        ((issues++))
    fi
    
    # Check for high failed login attempts
    failed_ssh=$(grep "$(date +%b\ %d)" /var/log/auth.log 2>/dev/null | grep -c "Failed password" || echo "0")
    if [ "$failed_ssh" -gt 20 ]; then
        ((issues++))
    elif [ "$failed_ssh" -gt 5 ]; then
        ((warnings++))
    fi
    
    # Display summary
    if [ "$issues" -eq 0 ] && [ "$warnings" -eq 0 ]; then
        echo -e "${GREEN}✓ System Security: GOOD${NC}"
        echo -e "${GREEN}  No critical issues or warnings detected${NC}"
    elif [ "$issues" -eq 0 ]; then
        echo -e "${YELLOW}⚠ System Security: MODERATE${NC}"
        echo -e "${YELLOW}  $warnings warnings detected${NC}"
    else
        echo -e "${RED}✗ System Security: ATTENTION REQUIRED${NC}"
        echo -e "${RED}  $issues critical issues, $warnings warnings${NC}"
        log_message "SECURITY ALERT: $issues critical issues detected"
    fi
    
    echo -e "${CYAN}Dashboard run completed at $DATE${NC}"
    echo ""
}

# Save report
save_report() {
    local report_file="$REPORT_DIR/security-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Security Dashboard Report"
        echo "Generated: $DATE"
        echo "Hostname: $(hostname)"
        echo "========================"
        echo ""
    } > "$report_file"
    
    # Re-run checks and append to report (without colors)
    {
        check_system_status
        check_ssh_security
        check_firewall_status
        check_fail2ban_status
        check_security_events
        check_network_connections
        check_emergency_users
        check_system_updates
        generate_summary
    } 2>&1 | sed 's/\x1b\[[0-9;]*m//g' >> "$report_file"
    
    echo -e "${CYAN}Report saved to: $report_file${NC}"
}

# Main execution
main() {
    # Clear screen for better readability
    clear
    
    print_header
    check_system_status
    check_ssh_security
    check_firewall_status
    check_fail2ban_status
    check_security_events
    check_network_connections
    check_emergency_users
    check_system_updates
    generate_summary
    
    # Save report if requested
    if [ "$1" = "--save" ] || [ "$1" = "-s" ]; then
        save_report
    fi
    
    # Continuous monitoring mode
    if [ "$1" = "--monitor" ] || [ "$1" = "-m" ]; then
        echo -e "${CYAN}Entering continuous monitoring mode (Ctrl+C to exit)...${NC}"
        while true; do
            sleep 300  # 5 minutes
            clear
            main
        done
    fi
}

# Show usage if help requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Security Dashboard - Server Security Monitoring"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h      Show this help message"
    echo "  --save, -s      Save report to file"
    echo "  --monitor, -m   Continuous monitoring mode"
    echo ""
    echo "Examples:"
    echo "  $0              Run dashboard once"
    echo "  $0 --save       Run dashboard and save report"
    echo "  $0 --monitor    Run in continuous monitoring mode"
    exit 0
fi

# Run main function
main "$@"
