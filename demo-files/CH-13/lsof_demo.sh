#!/usr/bin/env bash
# file_demo.sh — opens files so you can catch them with lsof

DIR="/tmp/lsof_demo"
mkdir -p "$DIR"

for i in $(seq 1 3); do
  echo "line $i" > "$DIR/f$i.txt"
  exec {fd}<"$DIR/f$i.txt"   # keep file descriptors open
done

echo "PID $$ has 3 files open. Run: lsof -p $$"
sleep 60
