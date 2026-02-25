#!/usr/bin/env bash

# ==========================================================
# Regex Demo Environment for "Linux for Everyone"
# Covers:
# - Wildcards vs regex
# - Anchors (^ $)
# - Character classes
# - Quantifiers (? * + {n,m})
# - Dot (.)
# - Grouping and alternation
# - BRE vs ERE
# - Writing, testing, and debugging regex
# ==========================================================

set -e

mkdir -p regex_vs_wildcards_demo
cd regex_vs_wildcards_demo || exit 1

# ----------------------------------------------------------
# system.log — anchors, alternation, color highlighting
# ----------------------------------------------------------
cat > system.log <<'EOF'
INFO System boot completed
ERROR Disk failure detected
WARNING Low memory condition
ERROR Network timeout
INFO Previous ERROR resolved
DEBUG Verbose output enabled
FAIL Disk write error
EOF

# ----------------------------------------------------------
# app.log — grouping + alternation
# ----------------------------------------------------------
cat > app.log <<'EOF'
INFO Application started
ERROR Failed to connect to database
WARNING Configuration file missing
DEBUG Verbose logging enabled
ERROR Timeout occurred
EOF

# ----------------------------------------------------------
# auth.log — end-of-line anchors
# ----------------------------------------------------------
cat > auth.log <<'EOF'
INFO User login successful
ERROR Invalid password failed
ERROR Account locked failed
INFO Session failed unexpectedly
INFO Session closed
EOF

# ----------------------------------------------------------
# log.txt — extraction and debugging (-o)
# ----------------------------------------------------------
cat > log.txt <<'EOF'
2024-01-15 User login successful
2023-12-02 Backup completed
Invalid date 24-01-2024 detected
2022-07-30 System update applied
Error occurred on 2024-13-99
EOF

# ----------------------------------------------------------
# data.txt — digits, grouping, BRE vs ERE
# ----------------------------------------------------------
cat > data.txt <<'EOF'
1
12
123
1234
12345
007
2024
ab
abab
ababab
abababab
aba
abc
EOF

# ----------------------------------------------------------
# words.txt — quantifiers (?, *, +) and dot (.)
# ----------------------------------------------------------
cat > words.txt <<'EOF'
gd
god
good
gooood
gooodbye
gold
color
colour
cat
cut
cot
c1t
c-t
combat
configuration_text
act
EOF

# ----------------------------------------------------------
# users.txt — format validation
# ----------------------------------------------------------
cat > users.txt <<'EOF'
root
admin
user1
user99
a1
9invalid
superroot
EOF

# ----------------------------------------------------------
# names.txt — anchors + character classes
# ----------------------------------------------------------
cat > names.txt <<'EOF'
alice
Bob
_charlie
dave99
Eve
9invalid
EOF

# ----------------------------------------------------------
# versions.txt — dot as placeholder
# ----------------------------------------------------------
cat > versions.txt <<'EOF'
v1.2.0
v1.2.3
v1.2.9
v1.3.0
v2.0.1
version1.2.3
EOF


# ----------------------------------------------------------
# access.log — dot (.) matching with fixed-width structure
# ----------------------------------------------------------
cat > access.log <<'EOF'
127.0.0.1 - - [12/Jan/2024] "GET /index.html HTTP/1.1" 200 OK
127.0.0.1 - - [12/Jan/2024] "POST /api/login HTTP/1.0" 201 Created
127.0.0.1 - - [12/Jan/2024] "GET /health HTTP/1.1" 204 No Content
127.0.0.1 - - [12/Jan/2024] "GET /admin HTTP/1.1" 404 Not Found
127.0.0.1 - - [12/Jan/2024] "GET /api/data HTTP/1.0" 500 Internal Server Error
EOF


# ----------------------------------------------------------
# Summary
# ----------------------------------------------------------
echo
echo "Regex demo environment created:"
ls -1
echo
echo "New quantifier demo:"
echo "  grep -E 'colou?r' words.txt"
echo