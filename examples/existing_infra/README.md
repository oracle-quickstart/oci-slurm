### Creating Slurm Cluster with Existing infra
This example shows the way to creating Slurm Cluster in Oracle Cloud Infrastructure with existing bastion host, networks, filesystem. 
You need to prepare the OCI Authentication parameters, bastion login info and subnet ocids for servers and clients.

After applying this example, you will got following result:
1. NIS related server and client will be created, NIS server is a seperate vm and nis clients residing on slurm control or compute node.
2. Slurm cluster, including one control node and optional number of compute nodes will be setup on new created vms;


### Using this example
Prepare one variable file named "terraform.tfvars" with the required information. The content of "terraform.tfvars" should look something like the following:
```bash
$ cat terraform.tfvars

### Authentication details
region="us-phoenix-1"
tenancy_ocid="ocid1.tenancy.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
user_ocid="ocid1.user.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
fingerprint="xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
private_key_path="~/.oci/oci_api_key.pem"

### Compartment
compartment_ocid="ocid1.compartment.oc1..xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

### Public/private keys used on the instance
ssh_public_key="~/.ssh/id_rsa.pub"
ssh_private_key="~/.ssh/id_rsa"
server_count = 2
client_count = 1
bastion_host= "XXX.XXX.XXX.XXX"
bastion_user= "XXX"
client_subnet_ids = [
"ocid1.subnet.oc1.phx.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
"ocid1.subnet.oc1.phx.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
"ocid1.subnet.oc1.phx.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
]
server_subnet_ids = [
"ocid1.subnet.oc1.phx.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
"ocid1.subnet.oc1.phx.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
"ocid1.subnet.oc1.phx.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
]

bastion_ssh_private_key="~/.ssh/id_rsa"

```

Then apply the example using the following commands:
```bash
$ terraform init
$ terraform plan
$ terraform apply
```
