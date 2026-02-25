#!/bin/bash
# busy.sh - simple CPU-bound demo for taskset

echo "PID $$ running..."
echo "Press Ctrl+C to stop."

# Kill background jobs on exit or Ctrl+C
trap "echo 'Cleaning up...'; kill 0" SIGINT EXIT

while true; do
    md5sum /dev/zero &>/dev/null &
    ps -o pid,comm,psr -p $$
    sleep 2
done
