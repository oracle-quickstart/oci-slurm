### Quick Start Creating Slurm Cluster 
This example shows the way to quick start creating Slurm Cluster in Oracle Cloud Infrastructure including its related bastion host, networks, filesystem. 
You only need to prepare the OCI Authentication parameters. 

After applying this example, you will got following result:
1. One bastion host is created;
2. Network related resource is created, including a vcn, a server subnet, a client subnet and so on;
3. Related filesystems are created, together with mount target used for share directory in slurm cluster;
4. NIS related server and client will be created, NIS server is a seperate vm and nis clients residing on slurm control or compute node.
5. Slurm cluster, including one control node and optional number of compute nodes will be setup on new created vms;

### Using this example
Prepare one variable file named "terraform.tfvars" with the required information. The content of "terraform.tfvars" should look something like the following:
```bash
$ cat terraform.tfvars

# OCI Authentication details
region="us-phoenix-1"
tenancy_ocid="ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
user_ocid="ocid1.user.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
fingerprint="xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
private_key_path="~/.oci/oci_api_key.pem"

# Compartment
compartment_ocid="ocid1.compartment.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Public/private keys used on the instance
ssh_public_key="~/.ssh/id_rsa.pub"
ssh_private_key="~/.ssh/id_rsa"
bastion_ssh_public_key="~/.ssh/id_rsa.pub"
bastion_ssh_private_key="~/.ssh/id_rsa"

```

Then apply the example using the following commands:
```bash
$ terraform init
$ terraform plan
$ terraform apply
```
