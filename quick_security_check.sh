#!/bin/bash
# Quick Security Check Script
# Run this regularly to verify your server security status

echo "=== QUICK SECURITY CHECK ==="
echo "Date: $(date)"
echo ""

# Check SSH access
echo "🔐 SSH Security Check:"
echo "Current SSH AllowUsers:"
grep "^AllowUsers" /etc/ssh/sshd_config || echo "⚠️  No AllowUsers restriction found"

echo ""
echo "SSH configuration test:"
sshd -t && echo "✅ SSH config valid" || echo "❌ SSH config invalid"

echo ""
echo "Active SSH sessions:"
who

echo ""
echo "🔥 Firewall Status:"
ufw status | head -10

echo ""
echo "🚫 fail2ban Status:"
systemctl is-active fail2ban && echo "✅ fail2ban running" || echo "❌ fail2ban not running"

echo ""
echo "Banned IPs:"
fail2ban-client status sshd 2>/dev/null | grep "Banned IP list" || echo "No IPs currently banned"

echo ""
echo "🔍 Recent Failed SSH Attempts:"
grep "Failed password" /var/log/auth.log | tail -5 | awk '{print $1, $2, $3, $9, $11}' || echo "No recent failures"

echo ""
echo "📊 System Load:"
uptime

echo ""
echo "💾 Disk Usage:"
df -h / | tail -1

echo ""
echo "🕒 Last Security Update:"
stat /var/log/unattended-upgrades/unattended-upgrades.log 2>/dev/null | grep Modify || echo "No automatic updates log found"

echo ""
echo "=== END SECURITY CHECK ==="
