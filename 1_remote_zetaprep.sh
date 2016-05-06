#!/bin/bash

# Change to the root dir
cd "$(dirname "$0")"
# Make sure you edit cluster.conf prior to running this. 
. ./cluster.conf

##########################
# Get a node list from the connecting node, save it to nodes.list
# Run the Package Manager for a clean copy of packages
# Upload the private key to the node
# Upload the runcmd.sh, nodes.list, and cluster.conf, install_scripts.list files to the cluster
# Upload zeta_packages.tgz to the cluster
# Upload the numbered scripts to the cluster
# Provide instructions on the next step


##########################
SSHHOST="${IUSER}@${IHOST}"

# Since we use these a lot I short cut them into variables
SCPCMD="scp -i ${PRVKEY}"
SSHCMD="ssh -i ${PRVKEY} -t ${SSHHOST}"

#########################

# Have to find a way to discover this

rm -rf nodes.list
for I in $INODES; do 
    echo "$I" >> nodes.list
done

cat nodes.list

NODE_CNT=$(cat ./nodes.list|wc -l)
if [ ! "$NODE_CNT" -gt 2 ]; then
   echo "Node Count is not greater than 3"
   echo "Node Count: $NODE_CNT"
    exit 1
fi

#####################
# Copy private key
echo "Copying private key"
$SCPCMD ${PRVKEY} ${SSHHOST}:/home/${IUSER}/.ssh/id_rsa
# Copy next step scripts and helpers
echo "Copying Scripts"
$SCPCMD runcmd.sh ${SSHHOST}:/home/${IUSER}/
$SCPCMD run_cmd_no_return.sh ${SSHHOST}:/home/${IUSER}/
$SCPCMD nodes.list ${SSHHOST}:/home/${IUSER}/
$SCPCMD install_scripts.list ${SSHHOST}:/home/${IUSER}/
$SCPCMD cluster.conf ${SSHHOST}:/home/${IUSER}/
$SCPCMD 2_zeta_user_prep.sh ${SSHHOST}:/home/${IUSER}/

SCRIPTS=`cat ./install_scripts.list`
for SCRIPT in $SCRIPTS ; do
    $SCPCMD $SCRIPT ${SSHHOST}:/home/${IUSER}/
done
echo ""
$SSHCMD "chmod +x runcmd.sh"
$SSHCMD "chmod +x run_cmd_no_return.sh"
$SSHCMD "chmod +x 2_zeta_user_prep.sh"

echo "Cluster Scripts have been prepped."
echo "Log into cluster node and execute user prep script"
echo ""
echo "Login to initial node:"
echo "> ssh -i ${PRVKEY} $SSHHOST"
echo ""
echo "Initiate next step:"
echo "> ./2_zeta_user_prep.sh"

