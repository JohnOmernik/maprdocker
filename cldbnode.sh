#!/bin/bash

MAPRVER="5.1.0"
# Docker Checks
if [[ -z $(which docker)  ]] ; then
        echo " docker could not be found on this server. Please install Docker version 1.6.0 or later."
    echo " If it is already installed Please update the PATH env variable." 
        exit
fi

CLUSTERNAME="zetapoc"

MEMTOTAL=11000000

declare -a container_ids
declare -a container_ips

# Launch the Control Nodes
cldbdisks="/dev/xvdb /dev/xvdc /dev/xvdd"

#cldb_cid=$(sudo docker run -d --privileged -h ${CLUSTERNAME}c1 -e "DISKLIST=$cldbdisks" -e "CLUSTERNAME=${CLUSTERNAME}" -e "MEMTOTAL=${MEMTOTAL}" docker.io/maprtech/mapr-control-cent67:${MAPRVER})
cldb_cid=$(sudo docker run -d --net=host --privileged -e "DISKLIST=$cldbdisks" -e "CLUSTERNAME=${CLUSTERNAME}" -e "MEMTOTAL=${MEMTOTAL}" docker.io/maprtech/mapr-control-cent67:${MAPRVER})

#container_ids[0]=$cldb_cid

#cldbip=$(sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${cldb_cid} )
#container_ips[0]=$cldbip
echo "Control Node IP : $cldbip   Docker ID: $cldb_cid  Starting the cluster: https://${cldbip}:8443/    login:mapr   password:mapr"
