# Running MapR on Docker
---

Can it be done? - Yes

## Example AWS
This could work for other things, just used AWS For fun
---
### Node setup
* I used Centos 7 from the Marketplace on D2.xlarge instances (CentOS 7 (x86_64) with Updates HVM)
* For my base setup, I created 3 of these instances
* I ensured they were all in the same network, and had public IPs
* I changed the base OS drive from 8 GB to 64 GB
* Setup security groups to allow all traffic from the subnet that they were put into (if they were in 10.0.0.0/24 I allowed all traffic in the security group)
* Obviously I allowed SSH (tcp/22) from the IP I was working to install from
* Spun them up. 

### Configuration
Once the instances are running, the next step is to update the configuration file included (cluster.conf) prior to install 
* Clone this git - cd into maprdocker
* Copy cluster.conf.default to cluster.conf
* Open cluster.conf in your favorite text editor. 
* Most of these values need updating, the template tries to document what they are and what you need. So I won't repeat here. Save with your values

### Execution
Now you execute the scripts in order. Follow along for play by play
* 1_remote_zetaprep.sh - This is run on your machine not any cluster machines. It assume you got your cluster.conf correct
* 2_zeta_user_prep.sh - This installs two users mapr and zetaadm.  It asks for a password and puts them on every node
* 3_zeta_install_docker.sh - This installs docker on all nodes. It takes a while but it checks itself and will let you know when its done
* 4_install_docker_reg.sh - This creates a local docker registry for easy of deployment. 
* 5_build_zk_docker.sh - This builds the image for Zookeeper
* 6_build_mapr_docker.sh - This builds the image for MapR
* 7_run_zk_docker.sh - This runs the Zookeepers per your instructions
* 8_run_mapr_docker.sh - This runs the mapr containers (including CLDB etc)

*Note* At this point, check your cluster.  To connect to it, I typically SSH to a public node and setup a proxy with SSH
ssh -i yourkey.pem -D8091 $IUSER@$IHOST 
(IUSER/IHOST is in your cluster.conf)

Then set browser to use proxy, connect to https://CLDB_INTERNAL_IP:8443.  It should be working 

The u/p was set in step 2_zeta_user_prep.sh

Also: If you want to install a M3, M5/M7 Trial or otherwise license, now is the time

Then do this:

* 9_install_loopback.sh - This (attempts) to install the loopback nfs on all nodes, however there is an issue right now



