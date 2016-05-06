#!/bin/bash


. ./cluster.conf

ZK_CMD="/opt/mapr/runzkdocker.sh"

cat > /home/zetaadm/runzk.sh << EOL3
#!/bin/bash
. ./cluster.conf
ME=\$(hostname)

CHK=\$(echo "\${ZKLIST}"|grep "\$ME")
# Check to see if this hose is in the ZK list
if [ "\$CHK" != "" ]; then
    if [ ! -d "/opt/mapr" ]; then
        sudo mkdir -p /opt/mapr/conf
        sudo chown mapr:mapr /opt/mapr/conf
        sudo chmod 755 /opt/mapr/conf

        sudo mkdir -p /opt/mapr/zkdata
        sudo chown zetaadm:zetaadm /opt/mapr/zkdata

        sudo mkdir -p /opt/mapr/zookeeper/logs
        sudo chown mapr:mapr /opt/mapr/zookeeper/logs
        sudo chmod 777 /opt/mapr/zookeeper/logs
    fi

    CHKID=\$(sudo cat /opt/mapr/zkdata/myid 2> /dev/null)
    if [ "\$CHKID" == "" ]; then
        for ZK in \$ZKLIST; do
            ID=\$(echo -n \$ZK|cut -d":" -f1)
            HNAME=\$(echo -n \$ZK|cut -d":" -f2)
            CPORT=\$(echo -n \$ZK|cut -d":" -f3)
            QPORT=\$(echo -n \$ZK|cut -d":" -f4)
            MPORT=\$(echo -n \$ZK|cut -d":" -f5)
            if [ "\$ME" == "\${HNAME}" ]; then
                sudo chown -R zetaadm:zetaadm /opt/mapr/zkdata
                echo \${ID} > /opt/mapr/zkdata/myid
                sudo chown -R mapr:mapr /opt/mapr/zkdata
                sudo chmod 750 /opt/mapr/zkdata
            fi
        done
    fi
    sudo docker run -d --net=host -e="ZOO_LOG4J_PROP=INFO,ROLLINGFILE" -e="ZOO_LOG_DIR=/opt/mapr/zookeeper/zookeeper-3.4.5/logs" -v=/opt/mapr/conf:/opt/mapr/conf:rw -v=/opt/mapr/zookeeper/logs:/opt/mapr/zookeeper/zookeeper-3.4.5/logs:rw -v=/opt/mapr/zkdata:/opt/mapr/zkdata:rw ${DOCKER_REG_URL}/zkdocker $ZK_CMD
else
    exit 1
fi
EOL3


HOSTFILE="./nodes.list"
HOSTS=`cat $HOSTFILE`
for HOST in $HOSTS; do
  scp -o StrictHostKeyChecking=no cluster.conf $HOST:/home/zetaadm/cluster.conf
  scp -o StrictHostKeyChecking=no runzk.sh $HOST:/home/zetaadm/runzk.sh
done
./runcmd.sh "chmod +x /home/zetaadm/runzk.sh"
./runcmd.sh "/home/zetaadm/runzk.sh"
