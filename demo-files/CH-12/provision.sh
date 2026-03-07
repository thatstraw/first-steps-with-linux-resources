#!/bin/bash
# Script to generate demonstration files for the Archives and Compression chapter

set -e  # Exit on error

echo "=== Creating demonstration files for Archives and Compression chapter ==="
echo

# Clean up any existing demo directory
if [ -d "archive-demo" ]; then
    echo "Removing existing archive-demo directory..."
    rm -rf archive-demo
fi

# Create main demo directory
mkdir -p archive-demo
cd archive-demo

echo "Creating project directory structure..."
# Create a sample project directory
mkdir -p project/{src,docs,config,logs}

# Add some source files
cat > project/src/main.py << 'EOF'
#!/usr/bin/env python3
"""
Main application entry point
"""

def main():
    print("Hello from the project!")
    
if __name__ == "__main__":
    main()
EOF

cat > project/src/utils.py << 'EOF'
"""
Utility functions for the project
"""

def helper_function():
    return "This is a helper function"
EOF

# Add documentation files
cat > project/docs/README.md << 'EOF'
# Project Documentation

This is a sample project for demonstrating tar archives.

## Features
- Feature 1
- Feature 2
- Feature 3

## Usage
Run the main script to see output.
EOF

cat > project/docs/INSTALL.md << 'EOF'
# Installation Instructions

1. Extract the archive
2. Navigate to the project directory
3. Run the main script

That's it!
EOF

# Add configuration files
cat > project/config/app.conf << 'EOF'
# Application Configuration
debug=true
log_level=INFO
max_connections=100
EOF

cat > project/config/database.conf << 'EOF'
# Database Configuration
host=localhost
port=5432
name=myapp_db
EOF

# Add log files with realistic content
cat > project/logs/access.log << 'EOF'
2025-01-01 10:23:45 INFO User logged in: alice
2025-01-01 10:24:12 INFO Request: GET /api/users
2025-01-01 10:24:15 INFO Response: 200 OK
2025-01-01 10:25:03 WARN Slow query detected: 1.2s
2025-01-01 10:26:31 INFO User logged out: alice
2025-01-01 10:27:18 ERROR Connection timeout: database
2025-01-01 10:27:45 INFO Retry successful
EOF

cat > project/logs/error.log << 'EOF'
2025-01-01 10:27:18 ERROR Connection timeout: database
2025-01-01 10:27:19 ERROR Stack trace follows
2025-01-01 10:27:19 ERROR   at connection.py line 45
2025-01-01 10:27:19 ERROR   at main.py line 123
EOF

# Create a simple README in project root
cat > project/README.md << 'EOF'
# Sample Project

This is a demonstration project for learning about tar archives.
EOF

echo "✓ Created project/ directory with sample files"
echo

# Create some standalone files for compression demos
echo "Creating standalone files for compression examples..."

cat > access.log << 'EOF'
192.168.1.100 - - [01/Jan/2025:10:00:00] "GET /index.html HTTP/1.1" 200 1234
192.168.1.101 - - [01/Jan/2025:10:00:05] "GET /about.html HTTP/1.1" 200 5678
192.168.1.102 - - [01/Jan/2025:10:00:10] "POST /api/login HTTP/1.1" 200 890
192.168.1.100 - - [01/Jan/2025:10:00:15] "GET /style.css HTTP/1.1" 200 2345
192.168.1.103 - - [01/Jan/2025:10:00:20] "GET /images/logo.png HTTP/1.1" 200 12345
192.168.1.101 - - [01/Jan/2025:10:00:25] "GET /api/users HTTP/1.1" 200 3456
192.168.1.104 - - [01/Jan/2025:10:00:30] "GET /contact.html HTTP/1.1" 404 567
EOF

echo "✓ Created access.log for gzip demonstration"
echo

# Create a reports directory for update/append demonstrations
echo "Creating reports directory for modification examples..."
mkdir -p reports

cat > reports/january.txt << 'EOF'
January 2025 Report
===================
Sales: $50,000
Expenses: $30,000
Profit: $20,000
EOF

cat > reports/february.txt << 'EOF'
February 2025 Report
====================
Sales: $55,000
Expenses: $32,000
Profit: $23,000
EOF

echo "✓ Created reports/ directory"
echo

# Create a logs directory with multiple log files
echo "Creating logs directory for wildcard demonstrations..."
mkdir -p logs

cat > logs/app.log << 'EOF'
2025-01-01 Application started
2025-01-01 Loading configuration
2025-01-01 Server listening on port 8080
EOF

cat > logs/database.log << 'EOF'
2025-01-01 Database connection established
2025-01-01 Running migrations
2025-01-01 Database ready
EOF

cat > logs/auth.log << 'EOF'
2025-01-01 Authentication service started
2025-01-01 Loading user database
2025-01-01 Authentication ready
EOF

# Add some non-log files to demonstrate wildcard filtering
cat > logs/README.txt << 'EOF'
Log Files Directory
===================
This directory contains application logs.
EOF

echo "✓ Created logs/ directory with mixed file types"
echo

# Create config files for wildcard demonstrations
mkdir -p configs

cat > configs/server.conf << 'EOF'
server_port=8080
server_host=0.0.0.0
EOF

cat > configs/app.conf << 'EOF'
app_name=DemoApp
app_version=1.0.0
EOF

cat > configs/database.conf << 'EOF'
db_host=localhost
db_port=5432
EOF

cat > configs/settings.txt << 'EOF'
This is not a config file
EOF

echo "✓ Created configs/ directory"
echo

# Create a backup directory structure
echo "Creating backup scenario files..."
mkdir -p backup-scenario/current
mkdir -p backup-scenario/modified

cat > backup-scenario/current/file1.txt << 'EOF'
Original content of file1
This file has not been modified
EOF

cat > backup-scenario/current/file2.txt << 'EOF'
Original content of file2
This file will be modified
EOF

cat > backup-scenario/current/file3.txt << 'EOF'
Original content of file3
This file has not been modified
EOF

# Create modified versions
cp backup-scenario/current/file1.txt backup-scenario/modified/
cat > backup-scenario/modified/file2.txt << 'EOF'
Original content of file2
This file will be modified
MODIFIED: New content added here!
EOF
cp backup-scenario/current/file3.txt backup-scenario/modified/
cat > backup-scenario/modified/file4.txt << 'EOF'
This is a new file added after the original backup
EOF

echo "✓ Created backup-scenario/ directories"
echo

# Create a summary file
cat > README.md << 'EOF'
# Archive Demo Files

This directory contains demonstration files for learning about archives and compression.

## Directory Structure

- **project/** - A sample project directory with source code, docs, config, and logs
- **reports/** - Sample report files for demonstrating append/update operations
- **logs/** - Multiple log files for wildcard demonstrations
- **configs/** - Configuration files for wildcard demonstrations
- **backup-scenario/** - Files for demonstrating incremental backups
- **access.log** - A standalone log file for gzip compression demos

## Common Commands to Try

### Basic Archive Creation
```bash
tar -cf project.tar project/
tar -czf project.tar.gz project/
tar -cJf project.tar.xz project/
```

### List Archive Contents
```bash
tar -tf project.tar
tar -tvf project.tar
```

### Extract Archives
```bash
tar -xf project.tar
tar -xzf project.tar.gz
```

### Compression of Single Files
```bash
gzip access.log        # Creates access.log.gz
gunzip access.log.gz   # Restores access.log
```

### Working with Wildcards
```bash
tar -cf configs-only.tar --wildcards 'configs/*.conf'
tar -cf logs-only.tar --wildcards 'logs/*.log'
```

### Appending to Archives
```bash
tar -cf reports.tar reports/january.txt
tar -rf reports.tar reports/february.txt
```

### Creating Zip Archives
```bash
zip -r project.zip project/
unzip -l project.zip
```

## Practice Exercises

1. Create an archive of the project/ directory
2. List its contents without extracting
3. Extract it to a different location using -C
4. Compress access.log with gzip
5. Create a tar.gz archive of just the .conf files
6. Create an incremental backup using the backup-scenario files

Have fun learning about archives and compression!
EOF

echo "✓ Created README.md with usage instructions"
echo
echo "=== Setup Complete! ==="
echo
echo "Demo files created in: $(pwd)"
echo
echo "Quick start commands:"
echo "  cd archive-demo"
echo "  tar -cf project.tar project/          # Create archive"
echo "  tar -tf project.tar                   # List contents"
echo "  tar -czf project.tar.gz project/      # Create compressed archive"
echo "  gzip access.log                       # Compress single file"
echo
echo "See README.md for more examples and exercises."