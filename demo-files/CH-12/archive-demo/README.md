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
