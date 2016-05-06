#!/bin/bash

. ./cluster.conf

ME=$(hostname)
if [ "$ME" != "${DOCKER_REG_HOST}" ]; then
    echo "Please run me on the host specified in the docker reg host in the cluster.conf"
fi

DOCKER_IMAGE_LOC="/opt/dockerimages"

sudo mkdir -p $DOCKER_IMAGE_LOC

sudo docker pull registry:2
sudo docker tag registry:2 zeta/registry:2

sudo docker run -d --net=host  -v=${DOCKER_IMAGE_LOC}:/var/lib/registry:rw zeta/registry:2



echo ""
echo ""
echo "Docker registry is now running at $DOCKER_REG_URL"
echo ""
echo ""

