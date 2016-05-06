#!/bin/bash

MAPRVER="5.1.0"
# Docker Checks
if [[ -z $(which docker)  ]] ; then
        echo " docker could not be found on this server. Please install Docker version 1.6.0 or later."
    echo " If it is already installed Please update the PATH env variable." 
        exit
fi





CLUSTERNAME="zetapoc"
NUMBEROFNODES=3
MEMTOTAL=11000000
DISKLISTFILE="/home/zetaadm/disks.txt"

if [[ ! -f ${DISKLISTFILE} ]]
then
    echo " Disklistile : ${DISKLISTFILE} doesn't exist"
    exit
fi


#declare -a disks=(`for i in /dev/sd[a-z]; do   [[ $(sfdisk -l $i | wc -l) -eq 2 ]]  && echo $i; done`)
declare -a disks=(`cat ${DISKLISTFILE}`)

if [[ ${#disks[@]} -eq 0 ]] 
then
    echo "There are no usable disks on this server."
    exit
fi

if [[ ${#disks[@]} -lt ${NUMBEROFNODES} ]] ; then
    echo " Not enough disks to run the requested configuration. "
    echo " This server has ${#disks[@]} disks : ${disks[@]}"
    echo " Each node requires a minimum of one disk. "
    exit
fi

if [[ ${NUMBEROFNODES} -eq 0 ]] ; then
    echo " Bye !"
    exit
fi


declare -a container_ids
declare -a container_ips

# Launch Data Nodes 
#data_cid=$(sudo docker run -d --privileged -h ${CLUSTERNAME}d${i} -e "CLDBIP=${cldbip}" -e "DISKLIST=${disks[$i]}" -e "CLUSTERNAME=${CLUSTERNAME}" -e "MEMTOTAL=${MEMTOTAL}" docker.io/maprtech/mapr-data-cent67:${MAPRVER})
data_cid=$(sudo docker run -d --net=host --privileged -e "CLDBIP=${cldbip}" -e "DISKLIST=${disks[$i]}" -e "CLUSTERNAME=${CLUSTERNAME}" -e "MEMTOTAL=${MEMTOTAL}" docker.io/maprtech/mapr-data-cent67:${MAPRVER})
container_ids[$i]=$data_cid
sleep 10
dip=$(sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${data_cid} )
container_ips[$i]=$dip
echo -e "$dip\t${CLUSTERNAME}d${i}.mapr.io\t${CLUSTERNAME}d${i}" >> /tmp/hosts.$$
