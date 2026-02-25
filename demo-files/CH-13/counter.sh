#!/bin/bash
i=1
while true; do
    echo "Count: $i" >> counter.log
    ((i++))
    sleep 5
done
