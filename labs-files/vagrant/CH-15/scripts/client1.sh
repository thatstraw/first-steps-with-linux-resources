#!/bin/bash

echo "=========================================="
echo "Configuring Client1..."
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

# Configure network
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
        - 192.168.20.10/24
      gateway4: 192.168.20.254
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF

# Set proper permissions (IMPORTANT!)
chmod 600 /etc/netplan/01-netcfg.yaml

# Apply the configuration
netplan apply
sleep 2

# Remove NAT default route if present
ip route del default via 10.0.2.2 dev $NAT_IFACE 2>/dev/null || true

echo ""
echo "Current routing table:"
ip route show

# Configure SSH to allow password authentication
echo "Configuring SSH for password authentication..."

sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

if [ -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf ]; then
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
fi

echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
systemctl restart ssh

# Install tools
apt-get update
apt-get install -y curl wget dnsutils net-tools traceroute iputils-ping ufw network-manager sshpass php

# Disable ufw
ufw --force disable
systemctl disable ufw

# =====================================================
# DEMO DATA GENERATION SECTION (For File Transfer Labs)
# =====================================================

echo "Generating demo files and sample web content..."

# Create project directory structure
mkdir -p /home/vagrant/demo-project/{config,logs,data,webapp}

# Sample configuration files
cat > /home/vagrant/demo-project/config/app.conf <<EOF
app_name=SysXplore Demo App
environment=development
db_host=localhost
db_port=5432
EOF

cat > /home/vagrant/demo-project/config/nginx.conf <<EOF
server {
    listen 80;
    server_name demo.local;
    root /var/www/demo;
}
EOF

# Generate demo log files
for i in {1..5}; do
    echo "$(date) INFO User login successful - session $RANDOM" >> /home/vagrant/demo-project/logs/app.log
done

# Generate demo data files
for i in {1..10}; do
    echo "Sample data line $i - ID: $RANDOM" >> /home/vagrant/demo-project/data/sample-data.txt
done

# Create static HTML demo site
cat > /home/vagrant/demo-project/webapp/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>SysXplore Demo</title>
</head>
<body>
    <h1>Welcome to the SysXplore Demo App</h1>
    <p>This page is used for scp, rsync, and http.server demonstrations.</p>
</body>
</html>
EOF

# Create simple PHP demo app
cat > /home/vagrant/demo-project/webapp/info.php <<EOF
<?php
echo "<h2>PHP Demo Page</h2>";
echo "Server IP: " . \$_SERVER['SERVER_ADDR'] . "<br>";
echo "Client IP: " . \$_SERVER['REMOTE_ADDR'] . "<br>";
echo "Date: " . date('Y-m-d H:i:s');
?>
EOF

# Set ownership
chown -R vagrant:vagrant /home/vagrant/demo-project

echo ""
echo "Demo content created in:"
echo "/home/vagrant/demo-project"
echo ""
echo "You can now demonstrate:"
echo " - scp file transfers"
echo " - rsync directory synchronization"
echo " - sftp interactive browsing"
echo " - python3 -m http.server"
echo " - php -S 0.0.0.0:8080"
echo ""

echo "=========================================="
echo "Client1 configured!"
echo "IP: 192.168.20.10/24"
echo "Gateway: 192.168.20.254"
echo "Internet: Working"
echo "Server LAN: NOT accessible (no route configured)"
echo "=========================================="