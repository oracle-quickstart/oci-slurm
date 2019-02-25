#!/bin/bash
# This script is created based on terraforminstall.sh coming from https://confluence.oci.oraclecorp.com/display/PM/Terraform+Training

#install required packages
sudo yum -y install terraform terraform-provider-oci python-oci-cli bzip2 cpio zip unzip dos2unix dialog curl jq git golang iputils wget screen tmux byobu elinks

#generate API keys
mkdir -p ~/.oci

#get latest oci terraform installer
LATEST="$(curl -sS https://github.com/terraform-providers/terraform-provider-oci/releases | tac | tac | grep -m1 "releases/tag" | awk -F "\"" '{ print $2 }'  | perl -pe '($_)=/([0-9]+([.][0-9]+)+)/')"
wget https://github.com/terraform-providers/terraform-provider-oci/archive/v$LATEST/linux_amd64.tar.gz

#deploy oci tf provider
tar xvzf linux_amd64.tar.gz
mkdir -p ~/.terraform.d/plugins
command cp terraform-provider-oci-${LATEST}/oci/* ~/.terraform.d/plugins
