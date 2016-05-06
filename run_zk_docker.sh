#!/bin/bash

#ZK_CMD="/opt/mapr/zookeeper/zookeeper-3.4.5/bin/zkServer.sh start-foreground"
ZK_CMD="/opt/mapr/runzkdocker.sh"

if [ "$1" == "1" ]; then
    sudo docker run -it --net=host -e="ZOO_LOG4J_PROP=INFO,ROLLINGFILE" -e="ZOO_LOG_DIR=/opt/mapr/zookeeper/zookeeper-3.4.5/logs" -v=/opt/mapr/conf:/opt/mapr/conf:rw -v=/opt/mapr/zookeeper/logs:/opt/mapr/zookeeper/zookeeper-3.4.5/logs:rw -v=/opt/mapr/zkdata:/opt/mapr/zkdata:rw zeta/zkdocker /bin/bash
elif [ "$1" == "2" ]; then
    sudo docker run -t --net=host -e="ZOO_LOG4J_PROP=INFO,ROLLINGFILE" -e="ZOO_LOG_DIR=/opt/mapr/zookeeper/zookeeper-3.4.5/logs" -v=/opt/mapr/conf:/opt/mapr/conf:rw -v=/opt/mapr/zookeeper/logs:/opt/mapr/zookeeper/zookeeper-3.4.5/logs:rw -v=/opt/mapr/zkdata:/opt/mapr/zkdata:rw zeta/zkdocker $ZK_CMD
else
    sudo docker run -d --net=host -e="ZOO_LOG4J_PROP=INFO,ROLLINGFILE" -e="ZOO_LOG_DIR=/opt/mapr/zookeeper/zookeeper-3.4.5/logs" -v=/opt/mapr/conf:/opt/mapr/conf:rw -v=/opt/mapr/zookeeper/logs:/opt/mapr/zookeeper/zookeeper-3.4.5/logs:rw -v=/opt/mapr/zkdata:/opt/mapr/zkdata:rw zeta/zkdocker $ZK_CMD
fi
