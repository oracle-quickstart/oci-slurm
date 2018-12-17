## Create VCN and Deploy Jenkins Cluster
This example creates a VCN in Oracle Cloud Infrastructure including default route table, DHCP options, security list and subnets from scratch, then use terraform_oci_slurm module to deploy a Slurm cluster(A Slurm control node and a Slurm compute node). 

### Using this example
Update terraform.tfvars.template with the required information and change file name to terraform.tfvars.

### Deploy the cluster  
Initialize Terraform:
```
$ terraform init
```
View what Terraform plans do before actually doing it:
```
$ terraform plan
```
Use Terraform to Provision resources and Slurm cluster on OCI:
```
$ terraform apply
```