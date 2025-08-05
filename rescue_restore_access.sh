#!/bin/bash
# Hetzner Rescue System - Restore SSH Access Script
# Run this script after logging into rescue system

set -e

echo "=== Hetzner Rescue System - SSH Access Restoration ==="

# Step 1: Identify and mount RAID array
echo "Step 1: Identifying storage devices..."
echo "Available block devices:"
lsblk
echo ""

echo "RAID status:"
cat /proc/mdstat
echo ""

# Assemble RAID if needed
echo "Assembling RAID arrays..."
mdadm --assemble --scan || echo "RAID assembly failed or no RAID detected"

echo ""
echo "Current RAID status after assembly attempt:"
cat /proc/mdstat
echo ""

echo "Available devices after RAID assembly:"
lsblk
echo ""

echo "Mounting root filesystem..."
# Create mount point
mkdir -p /mnt/serverdisk

# Try common root partition locations
if [ -e /dev/md0p1 ]; then
    ROOT_PARTITION="/dev/md0p1"
elif [ -e /dev/md0 ]; then
    ROOT_PARTITION="/dev/md0"
elif [ -e /dev/sda1 ]; then
    ROOT_PARTITION="/dev/sda1"
else
    echo "Please identify your root partition from lsblk output above"
    echo "Then run: mount /dev/YOUR_ROOT_PARTITION /mnt/serverdisk"
    exit 1
fi

echo "Mounting $ROOT_PARTITION..."
mount $ROOT_PARTITION /mnt/serverdisk

# Mount additional filesystems for chroot
echo "Preparing chroot environment..."
mount --bind /dev /mnt/serverdisk/dev
mount --bind /proc /mnt/serverdisk/proc
mount --bind /sys /mnt/serverdisk/sys
mount --bind /run /mnt/serverdisk/run

# Step 2: Reset UFW firewall
echo ""
echo "Step 2: Resetting UFW firewall..."
chroot /mnt/serverdisk /bin/bash << 'EOF'
# Reset UFW completely
ufw --force reset

# Allow SSH on port 22
ufw allow 22/tcp

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Enable UFW
ufw --force enable

# Show status
ufw status verbose
EOF

# Step 3: Fix SSH configuration
echo ""
echo "Step 3: Fixing SSH configuration..."
chroot /mnt/serverdisk /bin/bash << 'EOF'
# Backup original SSH config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)

# Reset SSH to standard port 22
sed -i 's/^Port .*/Port 22/' /etc/ssh/sshd_config
sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config

# Ensure SSH is enabled
sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# Ensure password authentication is enabled temporarily
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Fix AllowUsers to include emergency users (CRITICAL FIX)
sed -i 's/^AllowUsers cbwinslow$/AllowUsers cbwinslow emergency backup/' /etc/ssh/sshd_config
sed -i 's/^AllowUsers cbwinslow$/AllowUsers cbwinslow emergency backup/' /etc/ssh/sshd_config

echo "SSH configuration updated:"
grep -E "^(Port|PermitRootLogin|PasswordAuthentication|AllowUsers)" /etc/ssh/sshd_config
EOF

# Step 4: Disable/reset fail2ban
echo ""
echo "Step 4: Resetting fail2ban..."
chroot /mnt/serverdisk /bin/bash << 'EOF'
# Stop fail2ban
systemctl stop fail2ban || true

# Unban all IPs
fail2ban-client unban --all || true

# Reset fail2ban jails
if [ -f /etc/fail2ban/jail.local ]; then
    mv /etc/fail2ban/jail.local /etc/fail2ban/jail.local.backup.$(date +%Y%m%d)
fi

# Create minimal fail2ban config
cat > /etc/fail2ban/jail.local << 'FAIL2BAN_EOF'
[DEFAULT]
bantime = 600
findtime = 600
maxretry = 5

[sshd]
enabled = false
FAIL2BAN_EOF

# Disable fail2ban temporarily
systemctl disable fail2ban || true

echo "fail2ban disabled and reset"
EOF

# Step 5: Stop/disable other security services
echo ""
echo "Step 5: Disabling other security services..."
chroot /mnt/serverdisk /bin/bash << 'EOF'
# Stop and disable various security services
for service in snort suricata ossec; do
    systemctl stop $service 2>/dev/null || true
    systemctl disable $service 2>/dev/null || true
    echo "Disabled $service"
done

# Check for any custom iptables rules
iptables -L -n || true
iptables -F || true
iptables -X || true
iptables -t nat -F || true
iptables -t nat -X || true
iptables -t mangle -F || true
iptables -t mangle -X || true
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

echo "Cleared any residual iptables rules"
EOF

# Step 6: Create emergency access user
echo ""
echo "Step 6: Creating emergency access user..."
chroot /mnt/serverdisk /bin/bash << 'EOF'
# Create emergency user
useradd -m -s /bin/bash emergency || true
echo "emergency:emergency123" | chpasswd
usermod -aG sudo emergency

echo "Created emergency user: emergency/emergency123"
EOF

# Step 7: Enable SSH service
echo ""
echo "Step 7: Ensuring SSH service is enabled..."
chroot /mnt/serverdisk /bin/bash << 'EOF'
systemctl enable ssh
systemctl enable sshd
echo "SSH service enabled"
EOF

# Step 8: Cleanup and unmount
echo ""
echo "Step 8: Cleaning up..."
umount /mnt/serverdisk/run || true
umount /mnt/serverdisk/sys || true
umount /mnt/serverdisk/proc || true
umount /mnt/serverdisk/dev || true
umount /mnt/serverdisk

echo ""
echo "=== RESTORATION COMPLETE ==="
echo ""
echo "Changes made:"
echo "1. UFW firewall reset - only SSH (port 22) allowed"
echo "2. SSH port set to 22"
echo "3. fail2ban disabled and reset"
echo "4. snort, suricata, ossec disabled"
echo "5. iptables rules cleared"
echo "6. Emergency user created: emergency/emergency123"
echo "7. SSH service enabled"
echo ""
echo "Next steps:"
echo "1. Reboot the server into normal mode from Hetzner console"
echo "2. Wait 2-3 minutes for boot"
echo "3. Try SSH: ssh emergency@YOUR_SERVER_IP"
echo "4. Once logged in, reconfigure security services as needed"
echo ""
echo "IMPORTANT: Remember to re-secure your server after regaining access!"
