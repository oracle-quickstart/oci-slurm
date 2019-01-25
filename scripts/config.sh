#!/bin/bash

set -e -x


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
echo "PartitionName=debug Nodes="${compute_hostnames}" Default=YES MaxTime=INFINITE State=UP" >> /home/opc/config

sudo mv /home/opc/slurm.conf.tmp /etc/slurm/slurm.conf
sudo echo "include /mnt/shared/apps/slurm/slurm.conf" >> /etc/slurm/slurm.conf

sudo chmod 777  /etc/hosts
sudo cat /mnt/shared/hosts >> /etc/hosts

sudo cat /mnt/shared/authorized_keys  >> /home/opc/.ssh/authorized_keys

# To start Slurm node daemon
if [ "$1" = "compute" ]
then
    sudo echo "ReturnToService=2" >> /home/opc/config
    sudo mkdir -p /mnt/shared/apps/slurm/
    sudo cp /home/opc/config /mnt/shared/apps/slurm/slurm.conf
    echo "Restart Slurm Control Daemon on ${compute_hostnames} ..."
    sudo systemctl enable slurmd.service
    sudo systemctl restart slurmd.service
    sudo systemctl status slurmd.service

fi


# To start Slurm control daemon
if [ "$1" = "control" ]
then
### create /u01/HPC-Agent/hpc_agent.cfg
    touch ${slurm_fs_ip}
    sudo mkdir /u01/HPC-Agent/
    sudo chmod 777 /u01/HPC-Agent/
    sudo touch /u01/HPC-Agent/hpc_agent.cfg
    sudo chmod 777 /u01/HPC-Agent/hpc_agent.cfg
    sudo echo "{" >> /u01/HPC-Agent/hpc_agent.cfg
    sudo echo " \"SchedulerType\": \"slurm\"," >> /u01/HPC-Agent/hpc_agent.cfg
    sudo echo " \"SchedulerVersion\": \"18.08.4\"," >> /u01/HPC-Agent/hpc_agent.cfg
    sudo echo " \"SchedulerApiVersion\": \"18.08\"," >> /u01/HPC-Agent/hpc_agent.cfg
    sudo echo " \"AgentDaemonPidFilePath\": \"/tmp/agent-daemon.pid\"," >> /u01/HPC-Agent/hpc_agent.cfg
    sudo echo " \"AgentDaemonLogFilePath\": \"/tmp/agent-daemon.log\"," >> /u01/HPC-Agent/hpc_agent.cfg
    sudo echo " \"ClusterID\": \"1\" ," >> /u01/HPC-Agent/hpc_agent.cfg
    sudo echo " \"MQURL\": \"\" ," >> /u01/HPC-Agent/hpc_agent.cfg
    sudo echo " \"MQTopicID\": \"\"," >> /u01/HPC-Agent/hpc_agent.cfg
    sudo echo " \"MQCredential\": \"\" ," >> /u01/HPC-Agent/hpc_agent.cfg
    sudo echo " \"AccountServer\": \"${auth_ip}\" ," >> /u01/HPC-Agent/hpc_agent.cfg
    sudo echo " \"AccountServerType\": \"nis\" ," >> /u01/HPC-Agent/hpc_agent.cfg
    sudo echo " \"ClusterUserHome\": \"/UserHome\" ," >> /u01/HPC-Agent/hpc_agent.cfg
    sudo echo " \"SudoGroupName\": \"sudogroup\"" >> /u01/HPC-Agent/hpc_agent.cfg
    sudo echo "}" >> /u01/HPC-Agent/hpc_agent.cfg

### create message folders under HPC-Jobs directory
    sudo mkdir -p /u01/HPC-Jobs/ArchievedMessages
    sudo mkdir -p /u01/HPC-Jobs/GHostnameDemo
    sudo mkdir -p /u01/HPC-Jobs/MessageOutput
    sudo mkdir -p /u01/HPC-Jobs/Messages

    sudo chown opc:opc /u01/HPC-Jobs/ArchievedMessages
    sudo chown opc:opc /u01/HPC-Jobs/GHostnameDemo
    sudo chown opc:opc /u01/HPC-Jobs/MessageOutput
    sudo chown opc:opc /u01/HPC-Jobs/Messages

    sudo echo "ReturnToService=2" >> /home/opc/config
    sudo mkdir -p /mnt/shared/apps/slurm/
    sudo cp /home/opc/config /mnt/shared/apps/slurm/slurm.conf
    echo "Restart Slurm Control Daemon on ${control_hostname} ..."
    sudo systemctl enable slurmctld.service
    sudo systemctl restart slurmctld.service
    sudo systemctl status slurmctld.service
    echo y |sudo sacctmgr add cluster ocihpc 
    systemctl restart slurmdbd.service && sleep 10 && systemctl restart slurmctld.service  

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
fi
