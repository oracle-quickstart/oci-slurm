#! /bin/bash

echo "[DEFAULT]" >> ~/.oci/config
echo "user=" >> ~/.oci/config
echo "fingerprint=" >> ~/.oci/config
echo "tenancy=" >> ~/.oci/config
echo "region=" >> ~/.oci/config

replace=`cat terraform.tfvars | grep tenancy_ocid | awk -F= '{print $2}'`
sed -i "s/tenancy=/tenancy=$replace/"  ~/.oci/config
replace=`cat terraform.tfvars | grep user_ocid | awk -F= '{print $2}'`
sed -i "s/user=/user=$replace/"  ~/.oci/config
replace=`cat terraform.tfvars | grep fingerprint | awk -F= '{print $2}'`
sed -i "s/fingerprint=/fingerprint=$replace/"  ~/.oci/config
replace=`cat terraform.tfvars | grep region | awk -F= '{print $2}'`
sed -i "s/region=/region=$replace/"  ~/.oci/config
replace=`cat terraform.tfvars | grep private_key_path | awk -F= '{print $2}'`
echo "key_file=$replace" >>  ~/.oci/config
