#!/bin/bash
#######################################################################################################################################################
### This bootstrap script runs on glusterfs servers and does the following
### 1- install & start glusterfs server packages on all server nodes
### 2- Prepare bricks for creating glusterfs volume
### 3- Only open the needed ports in firewall
### 4- Add each sever into glusterfs peers
######################################################################################################################################################

exec &> bootstrap-server-logfile.txt
set -x

sudo touch ${slurm_fs_ip}
export enable_nis="${enable_nis}"
echo "enable_nis is $enable_nis"

if [ "$enable_nis" == "false" ]; then
    echo "enable_nis is false, nis will not be installed!"
    exit 0
fi

export nis_server_sercure_net_list="${nis_server_sercure_net_list}"
echo "nis_server_sercure_net_list is $nis_server_sercure_net_list"
nis_server_sercure_net_array=($nis_server_sercure_net_list)
nis_server_sercure_net_array_size="$${#nis_server_sercure_net_array[@]}"
echo "nis_server_sercure_net_array_size is $nis_server_sercure_net_array_size"

export nis_sudo_group_name="${nis_sudo_group_name}"
echo "nis_sudo_group_name is $nis_sudo_group_name"


yum -y install nfs-utils ypserv-2.31-11.el7.x86_64 rpcbind-0.2.0-47.el7.x86_64 expect-5.45-14.el7_1.x86_64
this_hostname=`hostname -f`
echo $this_hostname

export nis_domain_name="${nis_domain_name}"
echo "nis_domain_name is $nis_domain_name"
echo $nis_domain_name

ypdomainname $nis_domain_name
echo "NISDOMAIN=$nis_domain_name" >> /etc/sysconfig/network
cat /etc/sysconfig/network
cat /etc/hosts

if [ nis_server_sercure_net_array_size > 0]; then
    touch /var/yp/securenets
    for ((i=0; i<=nis_server_sercure_net_array_size-1; i++)); do
       export tmp_sercure_net=$${nis_server_sercure_net_array[i]}
       echo $tmp_sercure_net >>/var/yp/securenets
    done
fi

cat /var/yp/securenets
systemctl start rpcbind ypserv ypxfrd yppasswdd
systemctl enable rpcbind ypserv ypxfrd yppasswdd

/usr/bin/expect <<EOD
spawn /usr/lib64/yp/ypinit -m
expect "next host to add:"
send "\x04"
send "\r"
send "\r"
send "\r"
expect "\]\s*"
send "y\r"
interact
EOD

echo 'YPSERV_ARGS="-p 944"' >>/etc/sysconfig/network
echo 'YPXFRD_ARGS="-p 945"' >>/etc/sysconfig/network
cat /etc/sysconfig/network
sed -i 's/YPPASSWDD_ARGS=/YPPASSWDD_ARGS="--port 946"/g' /etc/sysconfig/yppasswdd
cat /etc/sysconfig/yppasswdd
firewall-cmd --add-service=rpc-bind --permanent
firewall-cmd --add-port=944/tcp --permanent
firewall-cmd --add-port=944/udp --permanent
firewall-cmd --add-port=945/tcp --permanent
firewall-cmd --add-port=945/udp --permanent
firewall-cmd --add-port=946/udp --permanent
firewall-cmd --reload
sestatus
setenforce 0
sestatus
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
cat /etc/selinux/config

systemctl restart rpcbind ypserv ypxfrd yppasswdd
useradd nistest
/usr/bin/expect <<EOD
spawn passwd nistest
expect "*New password:*"
send "DPdengjia8*\r"
expect ":"
send "DPdengjia8*\r"
expect "."
interact
EOD

#sudo  mount.nfs $ip:/home/ /home/
sudo mkdir /u01
#sudo  mount.nfs ${slurm_fs_ip}:/u01/ /u01/
sudo mkdir /UserHome
#sudo  mount.nfs ${slurm_fs_ip}:/UserHome /UserHome
sudo chmod 777 /etc/fstab
sudo echo "${slurm_fs_ip}:/u01 /u01 nfs" >> /etc/fstab
sudo echo "${slurm_fs_ip}:/UserHome /UserHome nfs" >> /etc/fstab
sudo mount -a

groupadd $nis_sudo_group_name
usermod -a -G $nis_sudo_group_name nistest
id nistest
echo '%${nis_sudo_group_name}      ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers
sed -i 's/$${nis_sudo_group_name}/${nis_sudo_group_name}/g' /etc/sudoers
cd /var/yp
ls
make
ls
getent passwd|grep nistest
getent group $nis_sudo_group_name
