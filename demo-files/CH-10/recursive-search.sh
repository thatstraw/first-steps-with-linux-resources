#!/bin/bash

# Create the folder structure
mkdir -p logs/dblogs
mkdir -p logs/applogs

# Create sample files in logs/
cat > logs/syslog.txt <<EOF
System boot completed successfully
Starting network services
Error: failed to bring up interface eth0
Service sshd started
EOF

cat > logs/messages.txt <<EOF
All services running
Low memory warning
Disk error detected on /dev/sda
EOF

# Create sample files in logs/dblogs/
cat > logs/dblogs/db1.log <<EOF
Database connection established
User 'admin' logged in
Query error: invalid syntax near SELECT
EOF

cat > logs/dblogs/db2.log <<EOF
Replication started
Replication completed
No error found here
EOF

# Create sample files in logs/applogs/
cat > logs/applogs/app1.log <<EOF
Application started
User session created
Unexpected error while reading config
EOF

cat > logs/applogs/app2.log <<EOF
Application shutting down
No issues detected
EOF

echo "Demo log files created under ./logs/"
