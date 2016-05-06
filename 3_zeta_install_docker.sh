#!/bin/bash
. ./cluster.conf

INST_FILE="/home/zetaadm/install_docker.sh"

cat > $INST_FILE << EOL
#!/bin/bash


DIST_CHK=\$(egrep -i -ho 'ubuntu|redhat|centos' /etc/*-release | awk '{print toupper(\$0)}' | sort -u)
UB_CHK=\$(echo \$DIST_CHK|grep UBUNTU)
RH_CHK=\$(echo \$DIST_CHK|grep REDHAT)
CO_CHK=\$(echo \$DIST_CHK|grep CENTOS)

if [ "\$UB_CHK" != "" ]; then
    INST_TYPE="ubuntu"
elif [ "\$RH_CHK" != "" ] || [ "\$CO_CHK" != "" ]; then
    INST_TYPE="rh_centos"
else
    echo "Unknown lsb_release -a version at this time only ubuntu, centos, and redhat is supported"
    echo \$DIST_CHK
    exit 1
fi
if [ "\$INST_TYPE" == "ubuntu" ]; then
# update apt-get
sudo apt-get -y update
sudo apt-get install -y nano
sudo apt-get install -y apt-transport-https ca-certificates
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" > ~/docker.list
sudo mv /home/zetaadm/docker.list /etc/apt/sources.list.d/
sudo apt-get -y update
sudo apt-get install -y docker-engine

# Start Docker
sudo service docker start

elif [ "\$INST_TYPE" == "rh_centos" ]; then
sudo yum install -y nano

sudo mkdir -p /etc/systemd/system/docker.service.d && sudo tee /etc/systemd/system/docker.service.d/override.conf <<- EOI8
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon --insecure-registry=${DOCKER_REG_URL}--storage-driver=overlay -H fd://
EOI8

# update yum
sudo yum -y update

# Add Docker repo to Yum
sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/\$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

# Install Docker
sudo yum -y install docker-engine

# Start Docker
sudo service docker start
else
    echo "Error"
    exit 1
fi

sudo sed -i -r 's/\# set tabsize 8/set tabsize 4/' /etc/nanorc
sudo sed -i -r 's/\# set tabstospaces/set tabstospaces/' /etc/nanorc
sudo sed -i -r 's/\# include /include /' /etc/nanorc

EOL


chmod +x $INST_FILE


HOSTFILE="./nodes.list"
HOSTS=`cat $HOSTFILE`
for HOST in $HOSTS; do
  scp -o StrictHostKeyChecking=no $INST_FILE $HOST:$INST_FILE
done



/home/zetaadm/run_cmd_no_return.sh "$INST_FILE"


NUM_NODES=$(cat ./nodes.list|wc -l)

NUM_INST=$(/home/zetaadm/runcmd.sh "sudo docker ps 2>&1"|grep "CONTAINER ID"|wc -l)

while [ $NUM_INST -ne $NUM_NODES ]
do
echo "Waiting for the number of nodes installed $NUM_INST to equal the number of total nodes $NUM_NODES in a 5 second loop. (Could take a while)"
NUM_INST=$(/home/zetaadm/runcmd.sh "sudo docker ps 2>&1"|grep "CONTAINER ID"|wc -l)
sleep 5
done





