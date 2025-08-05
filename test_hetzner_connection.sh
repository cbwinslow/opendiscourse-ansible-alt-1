#!/bin/bash

echo "Testing connection to Hetzner server..."
echo "IP: 95.217.106.172"
echo "User: root"
echo ""

# Test basic SSH connectivity
echo "1. Testing SSH connection..."
ssh -o ConnectTimeout=10 -o BatchMode=yes root@95.217.106.172 'echo "SSH connection successful!"' 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ SSH connection works!"
else
    echo "❌ SSH connection failed. Check your SSH key setup."
    echo "Make sure your public key is properly configured on the server."
fi

echo ""
echo "2. Testing Ansible connectivity..."
cd /home/cbwinslow/CascadeProjects/opendiscourse-ansible-alt/local-ai-hetzner

# Test Ansible ping
ansible all -i inventory/hosts.yml -m ping

echo ""
echo "If both tests pass, you can proceed with deployment!"
echo "Next steps:"
echo "  1. Review playbooks in local-ai-hetzner/playbooks/"
echo "  2. Run: ansible-playbook -i inventory/hosts.yml playbooks/main.yml"
