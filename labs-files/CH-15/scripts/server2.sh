#!/bin/bash

echo "=========================================="
echo "Configuring Server2 (DNS/DHCP)..."
echo "=========================================="

# Wait for network to be ready
sleep 5

# Get actual interface names
NAT_IFACE=$(ip route 2>/dev/null | grep default | awk '{print $5}' | head -1)
SERVER_IFACE=$(ip -o link show | grep -v "lo:" | awk -F': ' '{print $2}' | grep -v "$NAT_IFACE" | head -1)

echo "Detected interfaces:"
echo "  NAT interface: $NAT_IFACE"
echo "  Server LAN interface: $SERVER_IFACE"

# IMPORTANT: Keep route to Vagrant host (10.0.2.0/24) for SSH access
# Only remove the default route
ip route del default via 10.0.2.2 dev $NAT_IFACE 2>/dev/null || true

# Ensure route to Vagrant host network exists (for SSH)
ip route add 10.0.2.0/24 dev $NAT_IFACE 2>/dev/null || true

# Configure DNS first (before any package installation)
cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF

# Make resolv.conf immutable temporarily to prevent DHCP from overwriting
chattr +i /etc/resolv.conf || true

# Get interface name - find the server LAN interface  
ETH1=$SERVER_IFACE
echo "Using interface: $ETH1"

# Ensure interface is up
ip link set $ETH1 up
sleep 2

# Flush any existing IP addresses on server LAN interface
ip addr flush dev $ETH1

# Add static IP (only once)
ip addr add 192.168.10.20/24 dev $ETH1

# Add default route via internal firewall (only once)
ip route add default via 192.168.10.254 dev $ETH1 2>/dev/null || \
  echo "Default route already exists (this is OK)"

# Display current network configuration
echo ""
echo "Current IP addresses:"
ip addr show $ETH1 | grep "inet "
echo ""
echo "Current routing table:"
ip route show
echo ""

# Test connectivity to gateway with retry
echo "Testing connectivity to gateway (192.168.10.254)..."
GATEWAY_OK=false
for attempt in {1..5}; do
  if ping -c 1 -W 2 192.168.10.254 >/dev/null 2>&1; then
    echo "✓ Gateway reachable (attempt $attempt)"
    GATEWAY_OK=true
    break
  else
    echo "Attempt $attempt/5: Waiting for gateway..."
    sleep 2
  fi
done

if [ "$GATEWAY_OK" = false ]; then
  echo "✗ Gateway NOT reachable - check if internal-fw is up"
  echo "Continuing anyway..."
fi

# Test internet connectivity with retry logic
echo ""
echo "Testing internet connectivity (8.8.8.8)..."
INTERNET_OK=false
for attempt in {1..10}; do
  if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    echo "✓ Internet reachable (attempt $attempt)"
    INTERNET_OK=true
    break
  else
    echo "Attempt $attempt/10: Waiting for internet connectivity..."
    sleep 3
  fi
done

if [ "$INTERNET_OK" = false ]; then
  echo "✗ Internet NOT reachable after 10 attempts"
  echo "This usually means:"
  echo "  1. internal-fw is not forwarding traffic, or"
  echo "  2. edge-router is not providing NAT"
  echo ""
  echo "Continuing anyway - you can manually install packages later..."
  echo "Run: vagrant provision server2"
fi

# Test DNS resolution (using host instead of nslookup since it's not installed yet)
echo ""
echo "Testing DNS resolution..."
if host mirrors.rockylinux.org 8.8.8.8 2>/dev/null; then
  echo "✓ DNS resolution working"
else
  echo "⚠ DNS resolution failed (will retry after package install)"
fi

echo ""
echo "Installing packages..."
# Try package installation with better error handling
if [ "$INTERNET_OK" = true ]; then
  if dnf install -y bind bind-utils dhcp-server net-tools traceroute firewalld; then
    echo "✓ Packages installed successfully"
  else
    echo "✗ Package installation failed"
    echo "You can retry later with: vagrant provision server2"
  fi
else
  echo "⚠ Skipping package installation - no internet connectivity"
  echo "To install packages later:"
  echo "  1. Fix networking issues"
  echo "  2. Run: vagrant ssh server2"
  echo "  3. Run: sudo dnf install -y bind bind-utils dhcp-server net-tools traceroute firewalld"
fi

# Unmake resolv.conf immutable
chattr -i /etc/resolv.conf || true

# Disable firewalld by default - readerss will configure it
systemctl stop firewalld 2>/dev/null || true
systemctl disable firewalld 2>/dev/null || true

# Stop BIND and DHCP services - will be configured in exercises
systemctl stop named 2>/dev/null || true
systemctl disable named 2>/dev/null || true
systemctl stop dhcpd 2>/dev/null || true
systemctl disable dhcpd 2>/dev/null || true

echo ""
echo "=========================================="
echo "Server2 (DNS/DHCP) configured successfully!"
echo "=========================================="
echo "IP: 192.168.10.20/24"
echo "Gateway: 192.168.10.254 (Internal Firewall)"
echo "Interface: $ETH1"
echo "Internet: ✓ Working via Internal FW -> Edge Router"
echo "BIND (named): Installed but NOT configured"
echo "ISC DHCP Server: Installed but NOT configured"
echo "firewalld: DISABLED (ready for configuration)"
echo "=========================================="