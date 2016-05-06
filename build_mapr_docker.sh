#!/bin/bash

. ./mapr.conf

mkdir ./maprdocker


sudo docker rmi -f zeta/maprdocker

sudo docker pull ubuntu:latest

cat > ./maprdocker/dockerconf.sh << EOL3
#!/bin/bash
#This is run if there is no disktab in /opt/mapr/conf

/opt/mapr/server/mruuidgen > /opt/mapr/hostid
cat /opt/mapr/hostid > /opt/mapr/conf/hostid.\$\$

sed -i 's/service.command.mfs.heapsize.percent=.*/service.command.mfs.heapsize.percent=25/' /opt/mapr/conf/warden.conf
sed -i 's/service.command.mfs.heapsize.maxpercent=.*/service.command.mfs.heapsize.maxpercent=35/' /opt/mapr/conf/warden.conf

sed -i 's/AddUdevRules(list/#AddUdevRules(list/' /opt/mapr/server/disksetup


/opt/mapr/server/configure.sh -C \${CLDBS} -Z \${ZKS} -D \${DISKS} -N \${CLUSTERNAME} -u \${MUSER} -g \${MUSER} -no-autostart \${MAPR_CONF_OPTS}

/opt/mapr/server/dockerrun.sh

EOL3

cat > ./maprdocker/dockerrun.sh << EOL4
#!/bin/bash
service mapr-warden start

while true
do
sleep 5
done

EOL4


cat > ./maprdocker/Dockerfile << EOL
FROM ubuntu:latest

RUN adduser --disabled-login --gecos '' --uid=2500 zetaadm
RUN adduser --disabled-login --gecos '' --uid=2000 mapr

RUN usermod -a -G disk mapr


RUN echo "deb http://package.mapr.com/releases/v5.1.0/ubuntu/ mapr optional" > /etc/apt/sources.list.d/mapr.list
RUN echo "deb http://package.mapr.com/releases/ecosystem-5.x/ubuntu binary/" >> /etc/apt/sources.list.d/mapr.list

RUN apt-get update && apt-get install -y openjdk-8-jre wget perl netcat nfs-common

RUN apt-get install -y --allow-unauthenticated mapr-core mapr-core-internal mapr-fileserver mapr-hadoop-core mapr-hbase mapr-mapreduce1 mapr-mapreduce2 mapr-cldb mapr-webserver

ADD dockerconf.sh /opt/mapr/server/
ADD dockerrun.sh /opt/mapr/server/

RUN chmod +x /opt/mapr/server/dockerrun.sh && chmod +x /opt/mapr/server/dockerconf.sh

CMD ["/bin/bash"]

EOL
cd maprdocker

sudo docker build -t zeta/maprdocker .




sudo mkdir -p /opt/mapr/conf
sudo chown mapr:mapr /opt/mapr/conf
sudo chmod 755 /opt/mapr/conf

sudo mkdir -p /opt/mapr/logs
sudo chown mapr:mapr /opt/mapr/logs
sudo chmod 777 /opt/mapr/logs

sudo mkdir -p /opt/mapr/roles
sudo chown root:root /opt/mapr/roles


CHK=$(ls /opt/mapr/conf/|wc -l)
if [ "$CHK" == "0" ];then
    CID=$(sudo docker run -d zeta/maprdocker sleep 10)
    sudo docker cp ${CID}:/opt/mapr/conf /opt/mapr/
    sudo docker cp ${CID}:/opt/mapr/roles /opt/mapr/
fi


NSUB="export MAPR_SUBNETS=$SUBNETS"


sudo sed -i -r "s@#export MAPR_SUBNETS=.*@${NSUB}@g" /opt/mapr/conf/env.sh


