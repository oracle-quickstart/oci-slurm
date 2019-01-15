#!/bin/bash

set -e -x

# Check URL if exists
function validate_url() {
    if wget -S --spider $1 2>&1 | grep 'HTTP/1.1 200 OK'
    then
        return 0
    else
        return 1
    fi
}

# Add EPEL repo
sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# Installing required bits and bobs
sudo yum install -y expect nfs-utils munge-devel munge-libs readline-devel perl-ExtUtils-MakeMaker openssl-devel pam-devel rpm-build gcc perl-DBI perl-Switch munge mariadb-devel

# Oracle Object Storage Slurm RPM URL
OOSURL="https://objectstorage.us-phoenix-1.oraclecloud.com/n/dxterraformdev/b/SlurmPackage/o/slurm-${slurm_version}-rpm.tar.gz"

# Slurm Offical Download URL
SCHEDMDURL="https://download.schedmd.com/slurm/slurm-${slurm_version}.tar.bz2"

# Try Oracle Object Storage URL first to install Slurm
if validate_url $OOSURL
then
    echo "Download Slurm RPM packages from Oracle Object Storage..."
    wget $OOSURL
    tar -xzvf slurm-${slurm_version}-rpm.tar.gz
    sudo rpm -Uvh ~/RPMS/x86_64/*.rpm
else
    echo "Download Slurm RPM packages from SCHEDMD.COM..."
    wget $SCHEDMDURL
    # Building rpm packages
    rpmbuild -ta slurm-${slurm_version}.tar.bz2
    sudo rpm -Uvh ~/rpmbuild/RPMS/x86_64/*.rpm
fi

# Add user for slurm
sudo useradd slurm
sudo mkdir /var/log/slurm
sudo chown slurm. /var/log/slurm
sudo mkdir /var/spool/slurmd
sudo chown slurm: /var/spool/slurmd
sudo chmod 755 /var/spool/slurmd
sudo touch /var/log/slurmd.log
sudo chown slurm: /var/log/slurmd.log
sudo cp /etc/slurm/cgroup.conf.example /etc/slurm/cgroup.conf

# Open the default ports that Slurm uses
#sudo firewall-cmd --permanent --zone=public --add-port=6817/udp
#sudo firewall-cmd --permanent --zone=public --add-port=6817/tcp
#sudo firewall-cmd --permanent --zone=public --add-port=6818/tcp
#sudo firewall-cmd --permanent --zone=public --add-port=6819/tcp
#sudo firewall-cmd --permanent --zone=public --add-port=7321/tcp
#sudo firewall-cmd --reload
sudo systemctl stop firewalld.service
sudo systemctl disable firewalld.service

# Get munge key from Slurm control node
ssh -i ~/tmp.key -oStrictHostKeyChecking=no opc@${control_ip} "sudo cat /etc/munge/munge.key" > /home/opc/munge.key.tmp
sudo mv munge.key.tmp /etc/munge/munge.key
sudo chown -R munge: /etc/munge/ /var/log/munge/
sudo chmod 0700 /etc/munge/ /var/log/munge/
sudo chmod 400 /etc/munge/munge.key

# Configure Munge auth daemon
sudo systemctl start munge
sudo systemctl enable munge
sudo systemctl status munge

sudo mkdir /mnt/shared
chmod 777 /home/opc/scpipaddr
chmod 600 id_rsa_oci6
/home/opc/scpipaddr ${control_ip}
sleep 2
cat ipaddr2 |  egrep -o "([0-9]{1,3}.){3}[0-9]" >> ipaddr
ip=`cat ipaddr`
sudo mount.nfs  $ip:/shared /mnt/shared
sudo chmod 777 installmpi
./installmpi
sudo cat /mnt/shared/id_rsa.pub  >> /home/opc/.ssh/authorized_keys
sudo cat /etc/hosts  | grep "10." >> /mnt/shared/hosts
#sudo firewall-cmd --reload
