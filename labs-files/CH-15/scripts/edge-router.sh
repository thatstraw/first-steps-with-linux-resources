#!/bin/bash

echo "=========================================="
echo "Configuring Edge Router..."
echo "=========================================="

# Configure DNS fallback
cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF

# Enable IP forwarding 
echo 1 > /proc/sys/net/ipv4/ip_forward

# Make IP forwarding persistent
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

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

# Install ufw and tools with retries
echo "Installing packages..."
for i in {1..3}; do
  apt-get update && break
  echo "Attempt $i failed, retrying..."
  sleep 5
done
DEBIAN_FRONTEND=noninteractive apt-get install -y ufw net-tools inetutils-traceroute netfilter-persistent iptables-persistent

# DISABLE ufw by default - readerss will enable it
ufw --force disable
systemctl disable ufw

# Get actual interface names (VirtualBox uses enp0s3, enp0s8, etc.)
NAT_IFACE=$(ip route | grep default | awk '{print $5}')
TRANSIT_IFACE=$(ip -o link show | grep -v "lo:" | grep -v "$NAT_IFACE" | head -1 | awk -F': ' '{print $2}')

echo ""
echo "Detected interfaces:"
echo "  NAT interface (to internet): $NAT_IFACE"
echo "  Transit interface (to internal-fw): $TRANSIT_IFACE"
echo ""

# Flush all existing iptables rules
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Set default policies to ACCEPT (permissive for now - readerss will secure later)
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Configure NAT for internet access - MASQUERADE all traffic going out NAT interface
iptables -t nat -A POSTROUTING -o $NAT_IFACE -j MASQUERADE

# Allow forwarding between all interfaces
iptables -A FORWARD -j ACCEPT

# Save iptables rules
netfilter-persistent save

echo ""
echo "Verifying iptables configuration..."
echo "IP Forwarding status:"
cat /proc/sys/net/ipv4/ip_forward
echo ""
echo "FORWARD chain policy:"
iptables -L FORWARD -n | head -3

echo ""
echo "Network Configuration:"
ETH0_IP=$(ip -4 addr show $NAT_IFACE 2>/dev/null | grep inet | awk '{print $2}' || echo "Not available")
ETH1_IP=$(ip -4 addr show $TRANSIT_IFACE 2>/dev/null | grep inet | awk '{print $2}' || echo "Not available")
echo "  $NAT_IFACE (NAT): $ETH0_IP"
echo "  $TRANSIT_IFACE (Transit): $ETH1_IP"

echo ""
echo "Routing Table:"
ip route show

echo ""
echo "NAT Rules (POSTROUTING):"
iptables -t nat -L POSTROUTING -v -n | head -10

echo ""
echo "FORWARD Rules:"
iptables -L FORWARD -v -n | head -10

echo ""
echo "Testing internet connectivity..."
if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
  echo "✓ Edge Router can reach internet"
else
  echo "✗ Edge Router cannot reach internet"
fi

echo ""
echo "=========================================="
echo "Edge Router configured!"
echo "=========================================="
echo "$NAT_IFACE (NAT): $ETH0_IP"
echo "$TRANSIT_IFACE (Transit): 10.1.0.254/24"
echo "IP Forwarding: ENABLED"
echo "UFW Status: DISABLED (ready for configuration)"
echo "NAT: ENABLED on $NAT_IFACE (all traffic)"
echo "Forwarding: ENABLED (all interfaces)"
echo "=========================================="