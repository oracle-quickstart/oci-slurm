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
sudo yum install -y munge-devel munge-libs readline-devel perl-ExtUtils-MakeMaker openssl-devel pam-devel rpm-build gcc perl-DBI perl-Switch munge mariadb-devel

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
sudo firewall-cmd --reload