#!/bin/bash

#ZK_CMD="/opt/mapr/zookeeper/zookeeper-3.4.5/bin/zkServer.sh start-foreground"

. ./mapr.conf

if [ ! -f "/opt/mapr/conf/disktab" ]; then
    MAPR_CMD="/opt/mapr/server/dockerconf.sh"
else
    MAPR_CMD="/opt/mapr/server/dockerrun.sh"
fi

MYHOST=$(hostname)

MAPR_ENVS="-e=\"CLDBS=$CLDBS\" -e=\"MUSER=$MUSER\" -e=\"ZKS=$ZKS\" -e=\"DISKS=$DISKS\" -e=\"CLUSTERNAME=$CLUSTERNAME\" -e=\"MAPR_CONF_OPTS=$MAPR_CONF_OPTS\""

CONTROL_CHK=$(echo -n ${CLDBS}|grep ${MYHOST})

sudo rm -rf /opt/mapr/roles/webserver
sudo rm -rf /opt/mapr/roles/cldb

if [ "$CONTROL_CHK" != "" ]; then
    sudo touch /opt/mapr/roles/webserver
    sudo touch /opt/mapr/roles/cldb
fi


if [ "$1" == "1" ]; then
    sudo docker run -it --net=host ${MAPR_ENVS} --privileged -v=/opt/mapr/conf:/opt/mapr/conf:rw -v=/opt/mapr/logs:/opt/mapr/logs:rw -v=/opt/mapr/roles:/opt/mapr/roles:rw zeta/maprdocker /bin/bash
elif [ "$1" == "2" ]; then
    sudo docker run -t --net=host ${MAPR_ENVS} --privileged -v=/opt/mapr/conf:/opt/mapr/conf:rw -v=/opt/mapr/logs:/opt/mapr/logs:rw -v=/opt/mapr/roles:/opt/mapr/roles:rw zeta/maprdocker $MAPR_CMD
else
    sudo docker run -d --net=host ${MAPR_ENVS} --privileged -v=/opt/mapr/conf:/opt/mapr/conf:rw -v=/opt/mapr/logs:/opt/mapr/logs:rw -v=/opt/mapr/roles:/opt/mapr/roles:rw zeta/maprdocker $MAPR_CMD
fi
