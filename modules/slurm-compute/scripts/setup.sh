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
sudo firewall-cmd --permanent --zone=public --add-port=6817/udp
sudo firewall-cmd --permanent --zone=public --add-port=6817/tcp
sudo firewall-cmd --permanent --zone=public --add-port=6818/tcp
sudo firewall-cmd --permanent --zone=public --add-port=6819/tcp
sudo firewall-cmd --permanent --zone=public --add-port=7321/tcp
sudo firewall-cmd --reload


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