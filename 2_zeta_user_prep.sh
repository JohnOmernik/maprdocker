#!/bin/bash

###################
# Purpose of this script
# 1. Change and sync all mapr user passwords on all nodes
# 2. Create zetaadm user on all nodes with synced password
# 3. Ensure zetaadm is in the sudoers group on all nodes
# 4. Create zetaadm home volume in MapR-FS
# 5. Create ssh keypair for zetaadm - private in home volume, ensure public is in authorized_keys on all nodes
# 6. Copy remaining install scripts to /home/zetaadm 

. ./cluster.conf

SUDO_TEST=$(sudo whoami)
if [ "$SUDO_TEST" != "root" ]; then
    echo "This script must be run with a user with sudo privs"
    exit 1
fi

#DIST_CHK=$(lsb_release -a)
DIST_CHK=$(egrep -i -ho 'ubuntu|redhat|centos' /etc/*-release | awk '{print toupper($0)}' | sort -u)
UB_CHK=$(echo $DIST_CHK|grep UBUNTU)
RH_CHK=$(echo $DIST_CHK|grep REDHAT)
CO_CHK=$(echo $DIST_CHK|grep CENTOS)

if [ "$UB_CHK" != "" ]; then
    INST_TYPE="ubuntu"
    echo "Ubuntu"
elif [ "$RH_CHK" != "" ] || [ "$CO_CHK" != "" ]; then
    INST_TYPE="rh_centos"
    echo "Redhat"
else
    echo "Unknown lsb_release -a version at this time only ubuntu, centos, and redhat is supported"
    echo $DIST_CHK
    exit 1
fi
HOSTS="./nodes.list"
while read HOST; do
  ssh -t -t -n -o StrictHostKeyChecking=no $HOST "sudo sed -i \"s/Defaults    requiretty//g\" /etc/sudoers"
  ssh -t -t -n -o StrictHostKeyChecking=no $HOST "sudo sed -i \"s/Defaults   \!visiblepw//g\" /etc/sudoers"
done < $HOSTS

####################
###### ADD zetadm user and sync passwords on mapr User
echo "Prior to installing Zeta, there are two steps that must be taken to ensure two users exist and are in sync across the nodes"
echo "The two users are:"
echo ""
echo "mapr - This user is installed by the mapr installer and used for mapr services, however, we need to change the password and sync the password across the nodes"
echo "zetaadm - This is the user you can use to administrate your cluster and install packages etc."
echo ""
echo "Please keep track of these users passwords"
echo ""
echo ""
echo "Syncing mapr password on all nodes"
stty -echo
printf "Please enter new password for mapr user on all nodes: "
read mapr_PASS1
echo ""
printf "Please renter password for mapr: "
read mapr_PASS2
echo ""
stty echo

while [ "$mapr_PASS1" != "$mapr_PASS2" ]
do
    echo "Passwords entered for mapr user do not match, please try again"
    stty -echo
    printf "Please enter new password for mapr user on all nodes: "
    read mapr_PASS1
    echo ""
    printf "Please renter password for mapr: "
    read mapr_PASS2
    echo ""
    stty echo
done

echo ""
echo "Adding user zetaadm to all nodes"
stty -echo
printf "Please enter the zetaadm Password: "
read zetaadm_PASS1
echo ""

printf "Please Renter the zetaadm Password: "
read zetaadm_PASS2
echo ""
stty echo


while [ "$zetaadm_PASS1" != "$zetaadm_PASS2" ]
do
    echo "Passwords for zetaadm do not match, please try again"
    echo ""
    stty -echo
    printf "Please enter the zetaadm Password: "
    read zetaadm_PASS1
    echo ""

    printf "Please Renter the zetaadm Password: "
    read zetaadm_PASS2
    echo ""
    stty echo
done


if [ "$INST_TYPE" == "ubuntu" ]; then
   ADD1="adduser --disabled-login --gecos '' --uid=2500 zetaadm"
   ADD2="adduser --disabled-login --gecos '' --uid=2000 mapr"
   ZETA="echo \"zetaadm:$zetaadm_PASS1\"|chpasswd"
   MAPR="echo \"mapr:$mapr_PASS1\"|chpasswd"
elif [ "$INST_TYPE" == "rh_centos" ]; then
   ADD1="adduser --uid 2500 zetaadm"
   ADD2="adduser --uid 2000 mapr"
   ZETA="echo \"$zetaadm_PASS1\"|passwd --stdin zetaadm"
   MAPR="echo \"$mapr_PASS1\"|passwd --stdin mapr"
else
    echo "Relase not found, not sure why we are here, exiting"
    exit 1
fi

SCRIPT="/tmp/userupdate.sh"

cat > $SCRIPT << EOF
#!/bin/bash
$ADD1
$ADD2
echo "zetaadm ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
echo "mapr ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
$ZETA
$MAPR
EOF

HOSTS="./nodes.list"
while read HOST; do
  scp -o StrictHostKeyChecking=no $SCRIPT $HOST:$SCRIPT
done < $HOSTS
./runcmd.sh "sudo chmod 770 $SCRIPT"
./runcmd.sh "sudo $SCRIPT"
./runcmd.sh "sudo rm $SCRIPT"

####################
# Saving creds for later 
sudo mkdir -p /home/zetaadm/creds

cat > /home/${IUSER}/creds.txt << EOC
zetaadm:${zetaadm_PASS1}
mapr:${mapr_PASS1}
EOC
sudo mv /home/${IUSER}/creds.txt /home/zetaadm/creds/
sudo chown -R zetaadm:zetaadm /home/zetaadm/creds
sudo chmod 700 /home/zetaadm/creds



echo "Creating Keys"
sudo mkdir -p /home/zetaadm/.ssh
sudo chown zetaadm:zetaadm /home/zetaadm/.ssh

ssh-keygen -f ~/id_rsa -N ""

PUB=$(sudo cat ~/id_rsa.pub)
sudo mv id_rsa /home/zetaadm/.ssh/
sudo chown zetaadm:zetaadm /home/zetaadm/.ssh/id_rsa

./runcmd.sh "sudo mkdir -p /home/zetaadm/.ssh && echo \"$PUB\" > idpub && sudo mv idpub /home/zetaadm/.ssh/authorized_keys && sudo chown -R zetaadm:zetaadm /home/zetaadm/.ssh && sudo chmod 700 /home/zetaadm/.ssh && sudo chmod 600 /home/zetaadm/.ssh/authorized_keys"


echo "Moving Scripts to /home/zetaadm"

# Install Scripts
SCRIPTS=`cat ./install_scripts.list`
for S in $SCRIPTS ; do
    sudo cp ./$S /home/zetaadm/
    sudo chown zetaadm:zetaadm /home/zetaadm/$S
    sudo chmod +x /home/zetaadm/$S
done


# Settings, scripts list, node list, packages, and helper
sudo cp ./cluster.conf /home/zetaadm/
sudo cp ./install_scripts.list /home/zetaadm/
sudo cp ./nodes.list /home/zetaadm/
sudo cp ./runcmd.sh /home/zetaadm/
sudo cp ./run_cmd_no_return.sh /home/zetaadm/
#Fix Ownership
sudo chown zetaadm:zetaadm /home/zetaadm/cluster.conf
sudo chown zetaadm:zetaadm /home/zetaadm/nodes.list
sudo chown zetaadm:zetaadm /home/zetaadm/install_scripts.list
sudo chown zetaadm:zetaadm /home/zetaadm/runcmd.sh
sudo chown zetaadm:zetaadm /home/zetaadm/run_cmd_no_return.sh


# Zeta runcmd helper permissions
sudo chmod +x /home/zetaadm/runcmd.sh
sudo chmod +x /home/zetaadm/run_cmd_no_return.sh

echo "Users installed and scripts setup for zetaadm barring any errors reported above"
echo "You are done using $IUSER. At this point Please su to zetaadm, and move the /home/zetaadm directory to start step 3"
echo ""
echo "$ sudo su"
echo "$ su zetaadm"
echo "$ cd ~"
echo "$ ./3_zeta_install_docker.sh"
