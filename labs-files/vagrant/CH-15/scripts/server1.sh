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

# Install packages for web server, FTP server, and PHP
apt-get update
apt-get install -y apache2 vsftpd php php-apache2 libapache2-mod-php net-tools dnsutils traceroute iputils-ping ufw

# Disable ufw by default - students will configure it
ufw --force disable
systemctl disable ufw

# Configure and start web server
systemctl enable apache2

# Enable PHP module for Apache
a2enmod php*
systemctl reload apache2

# Configure vsftpd (FTP server)
echo "Configuring FTP server (vsftpd)..."

# Backup original vsftpd config
cp /etc/vsftpd.conf /etc/vsftpd.conf.backup

# Create secure vsftpd configuration
cat > /etc/vsftpd.conf <<EOF
# Basic Settings
listen=YES
listen_ipv6=NO
dirmessage_enable=YES
use_localtime=YES

# Anonymous Users - DISABLED
anonymous_enable=NO
anon_upload_enable=NO
anon_mkdir_write_enable=NO
anon_other_write_enable=NO

# Local Users - ENABLED
local_enable=YES
write_enable=YES
local_umask=022
file_open_mode=0666

# Security Settings
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/run/vsftpd/empty

# FTP Data Transfer
connect_from_port_20=YES
ftp_data_port=20
pasv_enable=YES
pasv_min_port=21100
pasv_max_port=21110

# Logging
xferlog_enable=YES
xferlog_std_format=YES
xferlog_file=/var/log/vsftpd.log

# Upload permissions
local_root=/var/www/html
chroot_list_enable=NO

# Connection limits
max_clients=50
max_per_ip=5

# User permissions
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO

# Banner
ftpd_banner=Welcome to Web Server FTP Service
EOF

# Create FTP user list (only users in this list can access FTP)
echo "vagrant" > /etc/vsftpd.userlist

# Create FTP upload directory and set permissions
mkdir -p /var/www/html/uploads
chown www-data:www-data /var/www/html/uploads
chmod 755 /var/www/html/uploads

# Allow vagrant user to write to web directory
usermod -a -G www-data vagrant
chown -R www-data:www-data /var/www/html
chmod -R 775 /var/www/html

# Enable and start vsftpd
systemctl enable vsftpd
systemctl start vsftpd

# Create test PHP page
cat > /var/www/html/info.php <<EOF
<?php
phpinfo();
?>
EOF

# Create upload test PHP page
cat > /var/www/html/upload.php <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>File Upload Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .upload-form { background: #f0f0f0; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>FTP Upload Test Page</h1>
    <div class="upload-form">
        <h3>Upload via Web Interface</h3>
        <form action="upload.php" method="post" enctype="multipart/form-data">
            Select file to upload:
            <input type="file" name="fileToUpload" id="fileToUpload">
            <input type="submit" value="Upload File" name="submit">
        </form>
        
        <?php
        if(isset(\$_POST["submit"])) {
            \$target_dir = "uploads/";
            \$target_file = \$target_dir . basename(\$_FILES["fileToUpload"]["name"]);
            
            if (move_uploaded_file(\$_FILES["fileToUpload"]["tmp_name"], \$target_file)) {
                echo "<p style='color: green;'>The file ". htmlspecialchars( basename( \$_FILES["fileToUpload"]["name"])). " has been uploaded.</p>";
            } else {
                echo "<p style='color: red;'>Sorry, there was an error uploading your file.</p>";
            }
        }
        ?>
        
        <h3>FTP Access Information</h3>
        <p><strong>FTP Server:</strong> 192.168.10.10</p>
        <p><strong>Username:</strong> vagrant</p>
        <p><strong>Password:</strong> vagrant</p>
        <p><strong>Upload Directory:</strong> /var/www/html/uploads</p>
    </div>
</body>
</html>
EOF

# Create test page
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Web Server - Server1</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .info { background: #f0f0f0; padding: 20px; border-radius: 5px; margin: 10px 0; }
        .services { background: #e8f4f8; padding: 20px; border-radius: 5px; margin: 10px 0; }
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
    
    <div class="services">
        <h2>Available Services</h2>
        <p><strong>Web Server:</strong> Apache2 with PHP support</p>
        <p><strong>FTP Server:</strong> vsftpd (Port 21)</p>
        <ul>
            <li><a href="info.php">PHP Info Page</a></li>
            <li><a href="upload.php">File Upload Test</a></li>
            <li>FTP Access: ftp://vagrant:vagrant@192.168.10.10</li>
        </ul>
    </div>
    
    <div class="info">
        <h3>FTP Connection Details</h3>
        <p><strong>Server:</strong> 192.168.10.10</p>
        <p><strong>Port:</strong> 21</p>
        <p><strong>Username:</strong> vagrant</p>
        <p><strong>Password:</strong> vagrant</p>
        <p><strong>Upload Directory:</strong> /var/www/html/uploads</p>
    </div>
    
    <p>This web server is in the Server LAN and initially NOT accessible from Client LAN.</p>
    <p>Students will configure routing and firewall rules to enable access.</p>
</body>
</html>
EOF
systemctl start apache2

echo "=========================================="
echo "Server1 (Web/FTP Server) ready!"
echo "=========================================="
echo "IP: 192.168.10.10/24"
echo "Gateway: 192.168.10.254 (Internal Firewall)"
echo "Internet: Working via Internal FW -> Edge Router"
echo ""
echo "Services Running:"
echo "  - Apache2 Web Server: http://192.168.10.10"
echo "  - PHP: Enabled (test at http://192.168.10.10/info.php)"
echo "  - vsftpd FTP Server: ftp://192.168.10.10"
echo ""
echo "FTP Configuration:"
echo "  - Anonymous access: DISABLED"
echo "  - Local users: ENABLED (users in /etc/passwd)"
echo "  - Allowed users: vagrant (in /etc/vsftpd.userlist)"
echo "  - Upload enabled: YES"
echo "  - Upload directory: /var/www/html/uploads"
echo "  - Chroot enabled: YES (users confined to /var/www/html)"
echo ""
echo "Test Pages:"
echo "  - http://192.168.10.10/ (main page)"
echo "  - http://192.168.10.10/info.php (PHP info)"
echo "  - http://192.168.10.10/upload.php (file upload test)"
echo ""
echo "Security:"
echo "  - ufw: DISABLED (ready for configuration)"
echo "  - FTP ports: 21 (control), 21100-21110 (passive data)"
echo "=========================================="