#!/bin/bash
#######################################################################################################################################################
### This bootstrap script runs on glusterfs clients and does the following
### 1- Install gluster packages on all nodes
### 2- Mount client to the glusterFS server volume
### 3- Check if mounted successfully by command "df"
######################################################################################################################################################

exec &> bootstrap-client-logfile.txt
set -x

export enable_nis="${enable_nis}"
echo "enable_nis is $enable_nis"

if [ "$enable_nis" == "false" ]; then
    echo "enable_nis is false, nis will not be installed!"
    exit 0
fi

export server_host_name="${server_host_name}"
echo "server_host_name is $server_host_name"

export nis_domain_name="${nis_domain_name}"
echo "nis_domain_name is $nis_domain_name"

export server_domain_name="${server_domain_name}"
echo "server_domain_name is $server_domain_name"

export nis_server_full_hostname=$server_host_name.$server_domain_name
echo "nis_server_full_hostname is $nis_server_full_hostname"

export nis_sudo_group_name="${nis_sudo_group_name}"
echo "nis_sudo_group_name is $nis_sudo_group_name"



yum -y install ypbind-1.37.1-9.el7.x86_64 rpcbind-0.2.0-47.el7.x86_64
ypdomainname $nis_domain_name
echo "NISDOMAIN=$nis_domain_name" >> /etc/sysconfig/network
cat /etc/sysconfig/network
authconfig --enablenis --nisdomain=$nis_domain_name --nisserver=$nis_server_full_hostname --enablemkhomedir --update
systemctl start rpcbind ypbind
echo '%${nis_sudo_group_name}      ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers
sed -i 's/$${nis_sudo_group_name}/${nis_sudo_group_name}/g' /etc/sudoers
getent passwd | grep nistest
getent group| grep nistest
getent group $nis_sudo_group_name
id nistest
