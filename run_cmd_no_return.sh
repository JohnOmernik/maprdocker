#!/bin/bash

HOSTFILE="./nodes.list"
HOSTS=`cat $HOSTFILE`

for NODE in $HOSTS; do
    ssh -o StrictHostKeyChecking=no $NODE "nohup $1 > /dev/null 2>&1 &"
done

