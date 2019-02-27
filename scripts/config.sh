#!/bin/bash
exec &> slurm_config.txt
set -e -x


if [ "$1" = "auth" ]
then
   sudo cat /u01/authorized_keys  >> /home/opc/.ssh/authorized_keys
   exit
fi



# Get Slurm compute node ip(s) and display name(s)
IFS=',' read -r -a ips <<<"${compute_ips}"
IFS=',' read -r -a host_names <<<"${compute_hostnames}"

# Update Slurm config file
sed -i 's/^\(ControlMachine=\).*/\1${control_hostname}/' /home/opc/slurm.conf.tmp
sed -i 's/^\(ControlAddr=\).*/\1${control_ip}/' /home/opc/slurm.conf.tmp

for index in "$${!ips[@]}"
do
    if [ -n "$(grep $${ips[index]} /home/opc/slurm.conf.tmp)" ]; then
        echo "Compute node $${host_names[index]} has already added to slurm config file."
    else
        echo "Adding $${host_names[index]} to slurm config file."
#        echo "NodeName=$${host_names[index]} NodeAddr=$${ips[index]} CPUs=2 State=UNKNOWN" >> /home/opc/slurm.conf.tmp
        echo "NodeName=$${host_names[index]} NodeAddr=$${ips[index]} CPUs=2 State=UNKNOWN" >> /home/opc/config
    fi
done

#echo "PartitionName=debug Nodes="${compute_hostnames}" Default=YES MaxTime=INFINITE State=UP" >> /home/opc/slurm.conf.tmp
#echo "PartitionName=debug Nodes="${compute_hostnames}" Default=YES MaxTime=INFINITE State=UP" >> /home/opc/config
# per ericyu, change to ALL makes it easier to add or remove nodes
echo "PartitionName=debug Nodes=ALL Default=YES MaxTime=INFINITE State=UP" >> /home/opc/config

# per ericyu, make sure executed slurm job won’t be purged in a short period
echo "MinJobAge=3600" >> /home/opc/config

sudo mv /home/opc/slurm.conf.tmp /etc/slurm/slurm.conf
sudo echo "include /mnt/shared/apps/slurm/slurm.conf" >> /etc/slurm/slurm.conf

#comment out these two lines as compute nodes may not need them
#sudo chmod 777  /etc/hosts
#sudo cat /mnt/shared/hosts >> /etc/hosts

sudo cat /mnt/shared/authorized_keys  >> /home/opc/.ssh/authorized_keys

sudo setsebool -P use_nfs_home_dirs 1

# To start Slurm node daemon
if [ "$1" = "compute" ]
then
    sudo echo "ReturnToService=2" >> /home/opc/config
    sudo mkdir -p /mnt/shared/apps/slurm/

#  get cpu count and replace it in the config 
    cpucount=`cat /proc/cpuinfo  | grep processor | wc -l`
    sed -i "s/CPUs=2/CPUs=$cpucount/g" /home/opc/config

    sudo cp /home/opc/config /mnt/shared/apps/slurm/slurm.conf
    echo "Restart Slurm Control Daemon on ${compute_hostnames} ..."
    sudo systemctl enable slurmd.service
    sudo systemctl restart slurmd.service
    sudo systemctl status slurmd.service

fi


# To start Slurm control daemon
if [ "$1" = "control" ]
then
    sudo chmod 777  /etc/hosts
    sudo cat /mnt/shared/hosts >> /etc/hosts

### create /opt/HPC-Agent/agent.conf
    touch ${slurm_fs_ip}
    sudo mkdir /opt/HPC-Agent/
    sudo chmod 777 /opt/HPC-Agent/
    sudo touch /opt/HPC-Agent/agent.conf
    sudo chmod 777 /opt/HPC-Agent/agent.conf
    sudo echo "{" >> /opt/HPC-Agent/agent.conf
    sudo echo " \"SchedulerType\": \"slurm\"," >> /opt/HPC-Agent/agent.conf
    sudo echo " \"SchedulerVersion\": \"18.08.4\"," >> /opt/HPC-Agent/agent.conf
    sudo echo " \"SchedulerApiVersion\": \"18.8\"," >> /opt/HPC-Agent/agent.conf
    sudo echo " \"AgentDaemonPidFilePath\": \"/tmp/agent-daemon.pid\"," >> /opt/HPC-Agent/agent.conf
    sudo echo " \"AgentDaemonLogFilePath\": \"/tmp/agent-daemon.log\"," >> /opt/HPC-Agent/agent.conf
    sudo echo " \"ClusterID\": \"1\" ," >> /opt/HPC-Agent/agent.conf
    sudo echo " \"MQURL\": \"\" ," >> /opt/HPC-Agent/agent.conf
    sudo echo " \"MQTopicID\": \"\"," >> /opt/HPC-Agent/agent.conf
    sudo echo " \"MQCredential\": \"\" ," >> /opt/HPC-Agent/agent.conf
    sudo echo " \"AccountServer\": \"${auth_ip}\" ," >> /opt/HPC-Agent/agent.conf
    sudo echo " \"AccountServerType\": \"nis\" ," >> /opt/HPC-Agent/agent.conf
    sudo echo " \"LoginServer\" : \"${slurm_bastion_ip}\"," >> /opt/HPC-Agent/agent.conf 
    sudo echo " \"PrivateKeyPathForLoginServer\" : \"${ssh_private_key}\"," >> /opt/HPC-Agent/agent.conf
    sudo echo " \"ClusterUserHome\": \"/UserHome\" ," >> /opt/HPC-Agent/agent.conf
    sudo echo " \"SudoGroupName\": \"sudogroup\"" >> /opt/HPC-Agent/agent.conf
    sudo echo "}" >> /opt/HPC-Agent/agent.conf

### for temp use, create message folders under HPC-Jobs directory
    sudo mkdir -p /u01/HPC-Jobs/ArchievedMessages
    sudo mkdir -p /u01/HPC-Jobs/GHostnameDemo
    sudo mkdir -p /u01/HPC-Jobs/MessageOutput
    sudo mkdir -p /u01/HPC-Jobs/Messages
    sudo mkdir -p /u01/HPC-Apps

    sudo chown opc:opc /u01/HPC-Jobs/ArchievedMessages
    sudo chown opc:opc /u01/HPC-Jobs/GHostnameDemo
    sudo chown opc:opc /u01/HPC-Jobs/MessageOutput
    sudo chown opc:opc /u01/HPC-Jobs/Messages
    sudo chown opc:opc /u01/HPC-Apps

## per ericyu, install these two packets
    sudo yum install -y python2-pip
    sudo pip install paramiko


    sudo echo "ReturnToService=2" >> /home/opc/config
    sudo mkdir -p /mnt/shared/apps/slurm/
#    sudo cp /home/opc/config /mnt/shared/apps/slurm/slurm.conf

    echo "Restart Slurm Control Daemon on ${control_hostname} ..."
    sudo systemctl enable slurmctld.service
    sudo systemctl restart slurmctld.service
    sudo systemctl status slurmctld.service
    echo y |sudo sacctmgr add cluster ocihpc 
    sudo systemctl restart slurmdbd.service && sleep 10 && sudo systemctl restart slurmctld.service  

#sudo sacctmgr add cluster ocihpc << EOF
#y
#EOF

    touch users.yml
    sudo echo \"---\" >> users.yml
    sudo echo \"users:\" >> users.yml
    sudo echo \"  - name: usernamehere\" >> users.yml
    sudo echo \"    key: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDgnEaelQQ4B1Kyr5wDEwAnD0hcwoj6lPRq9rWb4Dd+YpOsMahlctVV+0lKnSaarW+o1lYYqmnBXs3KR0X04IxGZ2qtjHc7FtJ70uMCT1w9zBiA/SIagRbATv0FpkHNQEIZSjtB1404eL7eavI8b/eNzxZ4n6Rr9BSg/y9GxHG0U6OHz4SmD8Rbfx3IKIEgE6+aksBPzCHE5rj95FB1hMKTmAEH2+i76Nn3REzK8T456bZc87rfN5IwKRUhaOtQbahV6QW9OBt71ZARxdTESLz0xeGaneCRhkoe/0y+GjcbQ0eGxclR0BHRgt4nsocGjbGgx5LEiRoWpiu+0pL7wSb1 opc@haojueterraform2\" >> users.yml
    sleep 10
    sinfo
    scontrol show nodes

# Check URL if exists
function validate_url() {
    if wget -S --spider $1 2>&1 | grep 'HTTP/1.1 200 OK'
    then
        return 0
    else
        return 1
    fi
}

# Download Agent
# latest code:  git clone ssh://git@bitbucket.oci.oraclecorp.com:7999/bigc/agent.git
# https://bitbucket.aka.lgl.grungy.us/projects/BIGC/repos/agent/browse
AgentURL="https://objectstorage.us-ashburn-1.oraclecloud.com/p/X7_2Er69pRqfVu228DbQQH4jpHUAUXNqbo0ZwTgYLaU/n/m1-hpc20190201s/b/SlurmAgent/o/agent.tar.gz"
AppURL="https://objectstorage.us-ashburn-1.oraclecloud.com/n/m1-hpcapptest0103/b/AppDeploy/o/App_deploy.sh"
if  validate_url $AgentURL && validate_url $AppURL 
then
    echo "Download Agent packages from Oracle Object Storage..."
    wget $AgentURL
    tar -xzvf agent.tar.gz 
    cp agent/src/* /opt/HPC-Agent/
    cp agent/resource/sample_input_json/*  /u01/HPC-Jobs/Messages/
    cp agent/resource/sample_slurm_batch_resource/hostname.slurm /u01/HPC-Jobs/GHostnameDemo/hostname.slurm
    wget $AppURL
    cp App_deploy.sh  /u01/HPC-Apps/
#    cp agent/resource/misc/App_deploy.sh  /u01/HPC-Apps/
    for((i=1;i<=6;i++));
    do
      sbatch /u01/HPC-Jobs/GHostnameDemo/hostname.slurm
    done
    rm -f agent.tar.gz
    rm -rf agent/
    python /opt/HPC-Agent/agent_daemon.py start
else
    echo "Agent packages download failure, please download it to slurm control node manually"
fi
fi
