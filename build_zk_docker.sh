#!/bin/bash

. ./mapr.conf

sudo docker rmi -f zeta/zkdocker

mkdir ./zkdocker

sudo docker pull ubuntu:latest

echo "To do: Set ZK Servers Later"

ZKOUT=$(echo -n $ZOOCFG|tr " " "\n")

cat > ./zkdocker/zoo.cfg << EOL1
# The number of milliseconds of each tick
tickTime=2000
# The number of ticks that the initial 
# synchronization phase can take
initLimit=20
# The number of ticks that can pass between 
# sending a request and getting an acknowledgement
syncLimit=10
# the directory where the snapshot is stored.
dataDir=/opt/mapr/zkdata
# the port at which the clients will connect
clientPort=5181
# max number of client connections
maxClientCnxns=100
#autopurge interval - 24 hours
autopurge.purgeInterval=24
#superuser to allow zk nodes delete
superUser=$MUSER
#readuser to allow read zk info for authenticated clients
readUser=anyone
# cldb key location
mapr.cldbkeyfile.location=/opt/mapr/conf/cldb.key
#security provider name
authMech=SIMPLE-SECURITY
# security auth provider
authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider
# use maprserverticket not userticket for auth
mapr.usemaprserverticket=true
$ZKOUT
EOL1

cat > ./zkdocker/runzkdocker.sh << EOL3
#!/bin/bash
su -c "/opt/mapr/zookeeper/zookeeper-3.4.5/bin/zkServer.sh start-foreground" mapr
EOL3


cat > ./zkdocker/Dockerfile << EOL
FROM ubuntu:latest

RUN adduser --disabled-login --gecos '' --uid=2500 zetaadm
RUN adduser --disabled-login --gecos '' --uid=2000 mapr

RUN apt-get update && apt-get install -y openjdk-8-jre wget perl netcat

RUN wget http://package.mapr.com/releases/v5.1.0/ubuntu/pool/optional/m/mapr-zk-internal/mapr-zk-internal_5.1.0.37549.GA-1_amd64.deb

RUN dpkg -i mapr-zk-internal_5.1.0.37549.GA-1_amd64.deb

ADD zoo.cfg /opt/mapr/zookeeper/zookeeper-3.4.5/conf/

ADD runzkdocker.sh /opt/mapr/

RUN chown -R mapr:mapr /opt/mapr/zookeeper && chown mapr:root /opt/mapr/runzkdocker.sh && chmod 755 /opt/mapr/runzkdocker.sh

CMD ["/bin/bash"]

EOL
cd zkdocker

sudo docker build -t zeta/zkdocker .


sudo mkdir -p /opt/mapr/conf
sudo chown mapr:mapr /opt/mapr/conf
sudo chmod 755 /opt/mapr/conf

sudo mkdir -p /opt/mapr/zkdata
sudo chown zetaadm:zetaadm /opt/mapr/zkdata

ME=$(hostname)
for ZK in $ZKLIST; do
    ID=$(echo -n $ZK|cut -d":" -f1)
    HNAME=$(echo -n $ZK|cut -d":" -f2)
    CPORT=$(echo -n $ZK|cut -d":" -f3)
    QPORT=$(echo -n $ZK|cut -d":" -f4)
    MPORT=$(echo -n $ZK|cut -d":" -f5)
    if [ "$ME" == "${HNAME}" ]; then
        echo ${ID} > /opt/mapr/zkdata/myid
    fi
done

sudo chown -R mapr:mapr /opt/mapr/zkdata
sudo chmod 750 /opt/mapr/zkdata


sudo mkdir -p /opt/mapr/zookeeper/logs
sudo chown mapr:mapr /opt/mapr/zookeeper/logs
sudo chmod 777 /opt/mapr/zookeeper/logs


