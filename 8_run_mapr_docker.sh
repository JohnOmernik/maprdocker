#!/bin/bash
. ./cluster.conf

cat > /home/zetaadm/runmapr.sh << EOL3
#!/bin/bash
RECONF=\$1
. ./cluster.conf

if [ ! -d "/opt/mapr" ]; then
    sudo mkdir -p /opt/mapr
fi
if [ ! -d "/opt/mapr/conf" ]; then
    sudo mkdir -p /opt/mapr/conf
    sudo chown mapr:mapr /opt/mapr/conf
    sudo chown 755 /opt/mapr/conf
fi
if [ ! -d "/opt/mapr/logs" ]; then
    sudo mkdir -p /opt/mapr/logs
    sudo chown mapr:mapr /opt/mapr/logs
    sudo chmod 777 /opt/mapr/logs
fi
if [ ! -d "/opt/mapr/roles" ]; then
    sudo mkdir -p /opt/mapr/roles
    sudo chown root:root /opt/mapr/roles
fi

CHK=\$(ls /opt/mapr/conf/|wc -l)
if [ "\$CHK" == "0" ];then
    CID=\$(sudo docker run -d \${DOCKER_REG_URL}/maprdocker sleep 10)
    sudo docker cp \${CID}:/opt/mapr/conf /opt/mapr/
    sudo docker cp \${CID}:/opt/mapr/roles /opt/mapr/
fi

NSUB="export MAPR_SUBNETS=$SUBNETS"
sudo sed -i -r "s@#export MAPR_SUBNETS=.*@\${NSUB}@g" /opt/mapr/conf/env.sh


if [ "\$RECONF" == "1" ]; then 
    MAPR_CMD="/opt/mapr/server/dockerreconf.sh"
else
    if [ ! -f "/opt/mapr/conf/disktab" ]; then
        MAPR_CMD="/opt/mapr/server/dockerconf.sh"
    else
        MAPR_CMD="/opt/mapr/server/dockerrun.sh"
    fi
fi
MYHOST=\$(hostname)

MAPR_ENVS="-e=\"CLDBS=\$CLDBS\" -e=\"MUSER=\$MUSER\" -e=\"ZKS=\$ZKS\" -e=\"DISKS=\$DISKS\" -e=\"CLUSTERNAME=\$CLUSTERNAME\" -e=\"MAPR_CONF_OPTS=\$MAPR_CONF_OPTS\""

CONTROL_CHK=\$(echo -n \${CLDBS}|grep \${MYHOST})

sudo rm -rf /opt/mapr/roles/webserver
sudo rm -rf /opt/mapr/roles/cldb

if [ "\$CONTROL_CHK" != "" ]; then
    sudo touch /opt/mapr/roles/webserver
    sudo touch /opt/mapr/roles/cldb
fi

sudo docker run -d --net=host \${MAPR_ENVS} --privileged -v=/opt/mapr/conf:/opt/mapr/conf:rw -v=/opt/mapr/logs:/opt/mapr/logs:rw -v=/opt/mapr/roles:/opt/mapr/roles:rw \${DOCKER_REG_URL}/maprdocker \$MAPR_CMD

EOL3


HOSTFILE="./nodes.list"
HOSTS=`cat $HOSTFILE`

for HOST in $HOSTS; do
  scp -o StrictHostKeyChecking=no cluster.conf $HOST:/home/zetaadm/cluster.conf
  scp -o StrictHostKeyChecking=no runmapr.sh $HOST:/home/zetaadm/runmapr.sh
done

./runcmd.sh "chmod +x /home/zetaadm/runmapr.sh"

# start CLDB containers
for HOST in $HOSTS; do
    MCHK=$(echo $CLDBS|grep $HOST)
    if [ "$MCHK" != ""  ]; then
        ssh $HOST "/home/zetaadm/runmapr.sh"
    fi
done
echo "Waiting 30 seconds for CLDBs to Start"
sleep 30
for HOST in $HOSTS; do
    MCHK=$(echo $CLDBS|grep $HOST)
    if [ "$MCHK" == ""  ]; then
        ssh $HOST "/home/zetaadm/runmapr.sh"
    fi
done
