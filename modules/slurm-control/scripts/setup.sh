#!/bin/bash
set -e -x

# Add EPEL repo
sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# Installing required bits and bobs
sudo yum install -y munge-devel munge-libs readline-devel perl-ExtUtils-MakeMaker openssl-devel pam-devel rpm-build gcc perl-DBI perl-Switch munge mariadb-devel

# Downloading the latest stable version of Slurm
wget https://download.schedmd.com/slurm/slurm-18.08.4.tar.bz2

# Building rpm packages
rpmbuild -ta slurm-18.08.4.tar.bz2

# Once done install rpms
sudo rpm -Uvh ~/rpmbuild/RPMS/x86_64/*.rpm


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
sudo mysql_secure_installation <<EOF

y
secret
secret
y
y
y
y
EOF

# Create SQL database
mysql --user=root --password=secret -Bse  "grant all on slurm_acct_db.* TO 'slurm'@'localhost' identified by 'some_pass' with grant option;"
mysql --user=root --password=secret -Bse  "create database slurm_acct_db;"

# Configure SLURM db backend
sudo mv ~/slurmdbd.conf.tmp /etc/slurm/slurmdbd.conf

# Enable DB service
sudo systemctl stop slurmdbd
sudo systemctl start slurmdbd
sudo systemctl enable slurmdbd
sudo systemctl status slurmdbd

# Configure Munge auth daemon
sudo  create-munge-key
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
