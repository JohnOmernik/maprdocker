#/bin/bash

service sshd start

IP=$(ip addr show eth0 | grep -w inet | awk '{ print $2}' | cut -d "/" -f1)

echo -e "${IP}\t$(hostname -f).mapr.io\t$(hostname) " >> /etc/hosts

#fallocate -l 20G /opt/mapr/docker.disk
#dd if=/dev/zero of=/opt/mapr/docker.disk bs=1G count=20

/opt/mapr/server/mruuidgen > /opt/mapr/hostid
cat /opt/mapr/hostid > /opt/mapr/conf/hostid.$$

cp /proc/meminfo /opt/mapr/conf/meminfofake

sed -i "/^MemTotal/ s/^.*$/MemTotal:     ${MEMTOTAL} kB/" /opt/mapr/conf/meminfofake
sed -i "/^MemFree/ s/^.*$/MemFree:     ${MEMTOTAL-10} kB/" /opt/mapr/conf/meminfofake
sed -i "/^MemAvailable/ s/^.*$/MemAvailable:     ${MEMTOTAL-10} kB/" /opt/mapr/conf/meminfofake

sed -i 's/AddUdevRules(list/#AddUdevRules(list/' /opt/mapr/server/disksetup

#sed -i 's/isDB=true/isDB=false/' /opt/mapr/conf/warden.conf
#sed -i 's/service.command.mfs.heapsize.percent=.*/service.command.mfs.heapsize.percent=8/' /opt/mapr/conf/warden.conf
#sed -i 's/service.command.mfs.heapsize.maxpercent=.*/service.command.mfs.heapsize.maxpercent=8/' /opt/mapr/conf/warden.conf

#/opt/mapr/server/configure.sh -C ${IP} -Z ${IP} -N dockerdemo.mapr.com -RM ${IP} -u mapr -D ${DISKLIST} -noDB
/opt/mapr/server/configure.sh -C ${IP} -Z ${IP} -D ${DISKLIST} -N ${CLUSTERNAME}.mapr.io -u mapr -g mapr -noDB -RM ${IP} 

echo "This container IP : ${IP}"

#/bin/bash

while true
do
sleep 5
done


rm historyserver nodemanager resourcemanager spark-historyserver 

#Need to fix MapR Subnets
#Need to fix Zookeeper or run sepearately. 



service mapr-warden stop
rm /opt/mapr/conf/disktab
rm /opt/mapr/conf/mapr-clusters.conf
/opt/mapr/server/configure.sh -C ip-10-22-87-33 -Z ip-10-22-87-33 -D /dev/xvdb,/dev/xvdc,/dev/xvdd -N zetapoc.mapr.io -u mapr -g mapr -RM ip-10-22-87-33

