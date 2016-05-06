#!/bin/bash



HOSTS="./nodes.list"

while read NODE; do
   ssh -o StrictHostKeyChecking=no $NODE "nohup $1 > /dev/null 2>&1 &"
done < $HOSTS

