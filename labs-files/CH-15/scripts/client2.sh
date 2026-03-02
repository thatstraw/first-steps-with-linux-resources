#!/bin/bash

echo "=========================================="
echo "Configuring Client2..."
echo "=========================================="

# Get actual interface names
NAT_IFACE=$(ip route | grep default | awk '{print $5}')
CLIENT_IFACE=$(ip -o link show | grep -v "lo:" | grep -v "$NAT_IFACE" | head -1 | awk -F': ' '{print $2}')

echo "Detected interfaces:"
echo "  NAT interface (will disable): $NAT_IFACE"
echo "  Client LAN interface: $CLIENT_IFACE"

# Configure DNS first
cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# Configure network with netplan 
cat > /etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  ethernets:
    $NAT_IFACE:
      dhcp4: true
      dhcp4-overrides:
        use-routes: false
        use-dns: false
      dhcp6: false
      dhcp6-overrides:
        use-routes: false
        use-dns: false
    $CLIENT_IFACE:
      addresses:
        - 192.168.20.20/24
      gateway4: 192.168.20.254
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF
netplan apply

# Wait for network to stabilize
sleep 2

# Double-check: Remove any NAT default route
ip route del default via 10.0.2.2 dev $NAT_IFACE 2>/dev/null || true

echo ""
echo "Current routing table:"
ip route show

# Configure SSH to allow password authentication
echo "Configuring SSH for password authentication..."
# Enable password authentication in SSH
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
# Also handle cloud-init config if it exists
if [ -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf ]; then
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
fi
# Ensure PasswordAuthentication is enabled
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
systemctl restart ssh

# Install tools
apt-get update
apt-get install -y curl wget dnsutils net-tools traceroute iputils-ping ufw network-manager

# Disable ufw
ufw --force disable
systemctl disable ufw

echo "=========================================="
echo "Client2 configured!"
echo "IP: 192.168.20.20/24"
echo "Gateway: 192.168.20.254 (Internal Firewall)"
echo "Internet: Working"
echo "Server LAN: NOT accessible (no route configured)"
echo "ufw: DISABLED (ready for configuration)"
echo ""
echo "To reach Server LAN (192.168.10.0/24), students will:"
echo "1. Add route via 192.168.20.254"
echo "2. Configure firewall rules on Internal Firewall"
echo "=========================================="