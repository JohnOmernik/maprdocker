#!/bin/bash

. ./cluster.conf

cat > /home/zetaadm/inst_loopback.sh << EOL3
#!/bin/bash

sudo yum install -y wget redhat-lsb-core

wget http://package.mapr.com/releases/v5.1.0/redhat/mapr-loopbacknfs-5.1.0.37549.GA-1.x86_64.rpm

sudo rpm -i mapr-loopbacknfs-5.1.0.37549.GA-1.x86_64.rpm

sudo cp /opt/mapr/conf/mapr-clusters.conf /usr/local/mapr-loopbacknfs/conf/

sudo service mapr-loopbacknfs start

sleep 5

sudo mkdir /mapr

sudo mount -t nfs -o nfsvers=3,noatime,rw,nolock,hard,intr localhost:/mapr /mapr
EOL3


HOSTFILE="./nodes.list"
HOSTS=`cat $HOSTFILE`
for HOST in $HOSTS; do
  scp -o StrictHostKeyChecking=no cluster.conf $HOST:/home/zetaadm/cluster.conf
  scp -o StrictHostKeyChecking=no inst_loopback.sh $HOST:/home/zetaadm/inst_loopback.sh
done
./runcmd.sh "chmod +x /home/zetaadm/inst_loopback.sh"
./runcmd.sh "/home/zetaadm/inst_loopback.sh"
