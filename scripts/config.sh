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
        echo "NodeName=$${host_names[index]} NodeAddr=$${ips[index]} CPUs=2 State=UNKNOWN" >> /home/opc/slurm.conf.tmp
    fi
done

echo "PartitionName=debug Nodes="${compute_hostnames}" Default=YES MaxTime=INFINITE State=UP" >> /home/opc/slurm.conf.tmp

sudo mv /home/opc/slurm.conf.tmp /etc/slurm/slurm.conf


# To start Slurm node daemon
if [ "$1" = "compute" ]
then
    echo "Restart Slurm Control Daemon on ${compute_hostnames} ..."
    sudo systemctl enable slurmd.service
    sudo systemctl restart slurmd.service
    sudo systemctl status slurmd.service
fi


# To start Slurm control daemon
if [ "$1" = "control" ]
then
    echo "Restart Slurm Control Daemon on ${control_hostname} ..."
    sudo systemctl enable slurmctld.service
    sudo systemctl restart slurmctld.service
    sudo systemctl status slurmctld.service
    sleep 10
    sinfo
    scontrol show nodes
fi