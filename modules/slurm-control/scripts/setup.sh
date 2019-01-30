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


# Installing required bits and bobs
sudo yum install -y nfs-utils munge-devel munge-libs readline-devel perl-ExtUtils-MakeMaker openssl-devel pam-devel rpm-build gcc perl-DBI perl-Switch munge mariadb-devel

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

# Add user for Slurm
sudo useradd slurm
sudo mkdir /var/log/slurm
sudo chown slurm. /var/log/slurm
sudo mkdir /var/spool/slurmctld
sudo chown slurm: /var/spool/slurmctld
sudo chmod 755 /var/spool/slurmctld
sudo touch /var/log/slurmctld.log
sudo chown slurm: /var/log/slurmctld.log
sudo touch /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log
sudo chown slurm: /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log

# Install MariaDB
sudo yum install -y mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo mysql_secure_installation << EOF

y
secret
secret
y
y
y
y
EOF

# Create SQL database
mysql --user=root --password=secret -Bse "grant all on slurm_acct_db.* TO 'slurm'@'localhost' identified by 'some_pass' with grant option;"
mysql --user=root --password=secret -Bse "create database slurm_acct_db;"

# Configure SLURM db backend
sudo mv ~/slurmdbd.conf.tmp /etc/slurm/slurmdbd.conf

# Enable DB service
sudo systemctl stop slurmdbd
sudo systemctl start slurmdbd
sudo systemctl enable slurmdbd
sudo systemctl status slurmdbd

# Configure Munge auth daemon
sudo create-munge-key
sudo systemctl start munge
sudo systemctl status munge
sudo systemctl enable munge

# Open the default ports that Slurm uses
sudo firewall-cmd --permanent --zone=public --add-port=6817/udp
sudo firewall-cmd --permanent --zone=public --add-port=6817/tcp
sudo firewall-cmd --permanent --zone=public --add-port=6818/tcp
sudo firewall-cmd --permanent --zone=public --add-port=6819/tcp
sudo firewall-cmd --permanent --zone=public --add-port=7321/tcp
sudo firewall-cmd --permanent --zone=public --add-port=60001-63000/tcp
sudo firewall-cmd --permanent --zone=public --add-service=nfs 
#sudo firewall-cmd --reload

#install pyslurm
sudo yum install Cython -y
sudo yum install git -y
sudo yum install python-devel -y
wget https://github.com/PySlurm/pyslurm/archive/18.08.0.zip -q
unzip 18.08.0.zip
cd pyslurm-18.08.0
sudo python setup.py build
sudo python setup.py install
cd -

# install environment-modules
sudo yum install environment-modules -y

#sudo systemctl stop firewalld.service
#sudo systemctl disable firewalld.service

sudo mkdir /mnt/shared
sudo chmod 777 /home/opc/getfsipaddr
/home/opc/getfsipaddr
cat ipaddr2 |  egrep -o "([0-9]{1,3}.){3}[0-9]" >> ipaddr3
ip=`cat ipaddr3`
sudo mount.nfs  $ip:/shared /mnt/shared

sudo touch /mnt/shared/authorized_keys
sudo chmod 777  /mnt/shared/authorized_keys
sudo cat /home/opc/.ssh/id_rsa.pub >>  /mnt/shared/authorized_keys
#sudo cat /mnt/shared/id_rsa.pub  >> /home/opc/.ssh/authorized_keys
sudo chmod 777 installmpi
#./installmpi
sudo touch /mnt/shared/hosts
sudo chmod 777  /mnt/shared/hosts
sudo cat /etc/hosts  | grep "10." >> /mnt/shared/hosts

#sudo  mount.nfs $ip:/home/ /home/
sudo mkdir /u01
#sudo  mount.nfs $ip:/u01/ /u01/
sudo mkdir /UserHome
#sudo  mount.nfs $ip:/UserHome /UserHome
sudo chmod 777 /etc/fstab
sudo echo "$ip:/u01 /u01 nfs" >> /etc/fstab
sudo echo "$ip:/UserHome /UserHome nfs" >> /etc/fstab
sudo mount -a

sudo firewall-cmd --reload
