#! /bin/bash

echo "[DEFAULT]" >> /home/opc/.oci/config
echo "user=" >> /home/opc/.oci/config
echo "fingerprint=" >> /home/opc/.oci/config
echo "tenancy=" >> /home/opc/.oci/config
echo "region=" >> /home/opc/.oci/config

replace=`cat terraform.tfvars | grep tenancy_ocid | awk -F= '{print $2}'`
sed -i "s/tenancy=/tenancy=$replace/"  /home/opc/.oci/config
replace=`cat terraform.tfvars | grep user_ocid | awk -F= '{print $2}'`
sed -i "s/user=/user=$replace/"  /home/opc/.oci/config
replace=`cat terraform.tfvars | grep fingerprint | awk -F= '{print $2}'`
sed -i "s/fingerprint=/fingerprint=$replace/"  /home/opc/.oci/config
replace=`cat terraform.tfvars | grep region | awk -F= '{print $2}'`
sed -i "s/region=/region=$replace/"  /home/opc/.oci/config
replace=`cat terraform.tfvars | grep private_key_path | awk -F= '{print $2}'`
echo "key_file=$replace" >>  /home/opc/.oci/config
sed -i 's/\s//g' /home/opc/.oci/config
sed -i 's/"//g' /home/opc/.oci/config
