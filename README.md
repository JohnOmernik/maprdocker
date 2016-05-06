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




