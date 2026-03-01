#!/bin/bash

echo "=========================================="
echo "Configuring Internal Firewall..."
echo "=========================================="

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Configure DNS
cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF

# Install firewalld and tools
dnf install -y firewalld net-tools bind-utils traceroute

# DISABLE firewalld by default - students will configure it
systemctl stop firewalld
systemctl disable firewalld

# Wait for network interfaces to be ready
sleep 3

# Get interface names
ETH0=eth0  # NAT interface (unused for our routing)
ETH1=eth1  # Transit network
ETH2=eth2  # Server LAN
ETH3=eth3  # Client LAN

echo "Network interfaces:"
echo "  $ETH0 (NAT - not used)"
echo "  $ETH1 (Transit to Edge Router)"
echo "  $ETH2 (Server LAN)"
echo "  $ETH3 (Client LAN)"
echo ""

# CRITICAL: Remove the Vagrant NAT default route but keep host route for SSH
# We want ALL traffic to go via Edge Router on transit network
echo "Removing Vagrant NAT default route..."
ip route del default via 10.0.2.2 2>/dev/null || echo "No NAT route to remove"

# Keep route to Vagrant host network (10.0.2.0/24) for SSH access
ip route add 10.0.2.0/24 dev $ETH0 2>/dev/null || echo "Host route already exists"

# Add our default route via Edge Router on transit network
echo "Adding default route via Edge Router (10.1.0.254)..."
ip route add default via 10.1.0.254 dev $ETH1

# Ensure IP forwarding is enabled at runtime
echo 1 > /proc/sys/net/ipv4/ip_forward

# Display routing configuration
echo ""
echo "Current routing table:"
ip route show
echo ""

# Test connectivity to Edge Router
echo "Testing connectivity to Edge Router (10.1.0.254)..."
if ping -c 2 -W 2 10.1.0.254; then
  echo "✓ Edge Router reachable"
else
  echo "✗ Edge Router NOT reachable - check if edge-router is up"
fi

# Test internet connectivity
echo ""
echo "Testing internet connectivity via Edge Router..."
if ping -c 2 -W 3 8.8.8.8; then
  echo "✓ Internet reachable via Edge Router"
else
  echo "✗ Internet NOT reachable"
  echo ""
  echo "Debugging information:"
  echo "1. Can we reach Edge Router? (already tested above)"
  echo "2. Checking if Edge Router can route..."
  echo ""
  echo "Current iptables NAT rules on this machine:"
  iptables -t nat -L -n -v
  echo ""
  echo "Attempting traceroute to 8.8.8.8:"
  traceroute -n -m 5 8.8.8.8 || true
fi

# Test DNS
echo ""
echo "Testing DNS resolution..."
if nslookup google.com >/dev/null 2>&1; then
  echo "✓ DNS working"
else
  echo "⚠ DNS resolution failed"
fi

echo ""
echo "Enabling NAT on eth1 (toward Edge Router)..."

# Install iptables-services (provides /etc/sysconfig/iptables)
dnf install -y iptables-services

# Flush any old rules
iptables -F
iptables -t nat -F

# Enable NAT for LANs -> Edge Router
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE

# Save configuration persistently
cat > /etc/sysconfig/iptables <<EOF
*nat
:PREROUTING ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A POSTROUTING -o eth1 -j MASQUERADE
COMMIT
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
EOF

# Enable and start iptables service
systemctl enable iptables
systemctl start iptables

echo "✓ NAT configured and persistent on eth1"

echo ""
echo "=========================================="
echo "Internal Firewall configured!"
echo "=========================================="
echo "Interfaces:"
echo "  eth0 (NAT): $(ip -4 addr show eth0 | grep inet | awk '{print $2}' | head -1) [NOT USED]"
echo "  eth1 (Transit): 10.1.0.2/24 -> Edge Router"
echo "  eth2 (Server LAN): 192.168.10.254/24 -> Servers"
echo "  eth3 (Client LAN): 192.168.20.254/24 -> Clients"
echo ""
echo "Routing:"
echo "  Default Gateway: 10.1.0.254 (Edge Router via Transit)"
echo "  IP Forwarding: ENABLED"
echo "  NAT: ENABLED (eth1 for LAN networks)"
echo ""
echo "Traffic Flow:"
echo "  Clients/Servers → Internal FW → Edge Router → Internet"
echo ""
echo "Security:"
echo "  firewalld: DISABLED"
echo ""
echo "IMPORTANT: No inter-LAN routing configured yet"
echo "=========================================="