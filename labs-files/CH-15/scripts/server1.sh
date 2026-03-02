#!/bin/bash

echo "=========================================="
echo "Configuring Server1 (Web Server)..."
echo "=========================================="

# Get actual interface names
NAT_IFACE=$(ip route | grep default | awk '{print $5}')
SERVER_IFACE=$(ip -o link show | grep -v "lo:" | grep -v "$NAT_IFACE" | head -1 | awk -F': ' '{print $2}')

echo "Detected interfaces:"
echo "  NAT interface (will disable): $NAT_IFACE"
echo "  Server LAN interface: $SERVER_IFACE"

# Configure static network with gateway to internal firewall
# CRITICAL: Keep NAT interface for SSH, but no default route
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
    $SERVER_IFACE:
      addresses:
        - 192.168.10.10/24
      gateway4: 192.168.10.254
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF

# Apply network configuration
netplan apply

# Wait for network to stabilize
sleep 2

# Double-check: Remove any NAT default route that might have been added
ip route del default via 10.0.2.2 dev $NAT_IFACE 2>/dev/null || true

echo ""
echo "Current routing table:"
ip route show

# Test connectivity to gateway
echo ""
echo "Testing connectivity to internal firewall (192.168.10.254)..."
if ping -c 2 192.168.10.254 >/dev/null 2>&1; then
  echo "✓ Internal firewall reachable"
else
  echo "✗ Internal firewall NOT reachable"
fi

# Test internet via our network path
echo ""
echo "Testing internet connectivity..."
if ping -c 2 8.8.8.8 >/dev/null 2>&1; then
  echo "✓ Internet reachable"
  echo ""
  echo "Verifying traffic path (should go via 192.168.10.254):"
  traceroute -n -m 3 8.8.8.8 | head -5
else
  echo "✗ Internet NOT reachable"
fi

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

# Install packages for web server
apt-get update
apt-get install -y apache2 net-tools dnsutils traceroute iputils-ping ufw

# Disable ufw by default - students will configure it
ufw --force disable
systemctl disable ufw

# Configure and start web server
systemctl enable apache2

# Create test page
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Web Server - Server1</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .info { background: #f0f0f0; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Welcome to Web Server (Server1)</h1>
    <div class="info">
        <p><strong>Hostname:</strong> $(hostname)</p>
        <p><strong>IP Address:</strong> 192.168.10.10</p>
        <p><strong>Network:</strong> Server LAN (192.168.10.0/24)</p>
        <p><strong>Time:</strong> $(date)</p>
    </div>
    <p>This web server is in the Server LAN and initially NOT accessible from Client LAN.</p>
    <p>Students will configure routing and firewall rules to enable access.</p>
</body>
</html>
EOF
systemctl start apache2

echo "=========================================="
echo "Server1 (Web Server) ready!"
echo "IP: 192.168.10.10/24"
echo "Gateway: 192.168.10.254 (Internal Firewall)"
echo "Internet: Working via Internal FW -> Edge Router"
echo "Web Server: Running on port 80 (Apache2)"
echo "ufw: DISABLED (ready for configuration)"
echo "=========================================="