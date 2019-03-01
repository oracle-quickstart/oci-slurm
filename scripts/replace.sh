#! /bin/bash

echo "[DEFAULT]" >> ~/.oci/configbak
echo "user=" >> ~/.oci/configbak
echo "fingerprint=" >> ~/.oci/configbak
echo "tenancy=" >> ~/.oci/configbak
echo "region=" >> ~/.oci/configbak

replace=`cat terraform.tfvars | grep tenancy_ocid | awk -F= '{print $2}'`
sed -i "s/tenancy=/tenancy=$replace/"  ~/.oci/configbak
replace=`cat terraform.tfvars | grep user_ocid | awk -F= '{print $2}'`
sed -i "s/user=/user=$replace/"  ~/.oci/configbak
replace=`cat terraform.tfvars | grep fingerprint | awk -F= '{print $2}'`
sed -i "s/fingerprint=/fingerprint=$replace/"  ~/.oci/configbak
replace=`cat terraform.tfvars | grep region | awk -F= '{print $2}'`
sed -i "s/region=/region=$replace/"  ~/.oci/configbak
replace=`cat terraform.tfvars | grep private_key_path | awk -F= '{print $2}'`
echo "key_file=$replace" >>  ~/.oci/configbak
