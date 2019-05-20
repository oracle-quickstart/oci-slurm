# oci-quickstart-slurm

These are Terraform modules that deploy [Slurm](https://slurm.schedmd.com/) on [Oracle Cloud Infrastructure (OCI)](https://cloud.oracle.com/en_US/cloud-infrastructure).

## About
The Slurm Module installs a Terraform-based Slurm cluster on Oracle Cloud Infrastructure (OCI). A Slurm cluster typically involves one Slurm Control node coupled with one or more Slurm compute nodes.

## Prerequisites
1. See the [Oracle Cloud Infrastructure Terraform Provider docs](https://www.terraform.io/docs/providers/oci/index.html) for information about setting up and using the Oracle Cloud Infrastructure Terraform Provider.
2. An existing VCN with subnets The subnets need internet access in order to download Slurm.


## What's a Module?
A module is a canonical, reusable definition for how to run a single piece of infrastructure, such as a database or server cluster. Each module is created using Terraform, and includes automated tests, examples, and documentation. It is maintained both by the open source community and companies that provide commercial support.

Instead of figuring out the details of how to run a piece of infrastructure from scratch, you can reuse existing code that has been proven in production. And instead of maintaining all that infrastructure code yourself, you can leverage the work of the module community to pick up infrastructure improvements through a version number bump.

## How to use this Module
Each Module has the following folder structure:
* [root](./): Contains a root module calls slurm-control and slurm-compute sub-modules to create a Slurm cluster in OCI.
* [modules](./modules): Contains the reusable code for this module, broken down into one or more modules.
* [examples](./examples/): Contains examples of how to use the modules.

The following code shows how to deploy Slurm Cluster servers using this module:

```txt
module "slurm-cluster" {
  source              = "git::ssh://git@bitbucket.aka.lgl.grungy.us:7999/tfs/terraform-oci-slurm.git?ref=dev"
  compartment_ocid    = "${var.compartment_ocid}"
  ssh_authorized_keys = "${var.ssh_authorized_keys}"
  ssh_private_key     = "${var.ssh_private_key}"
  control_ad          = "${data.template_file.ad_names.*.rendered[0]}"
  control_subnet_id   = "${oci_core_subnet.slurmcontrol.id}"
  control_image_id    = "${var.image_id[var.region]}"
  compute_ad          = "${data.template_file.ad_names.*.rendered[1]}"
  compute_subnet_id   = "${oci_core_subnet.slurmcompute.id}"
  compute_image_id    = "${var.image_id[var.region]}"
  bastion_host        = "${oci_core_instance.slurmbastion.public_ip}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
}
```

Argument | Description
--- | ---
compartment_ocid | OCID of the compartment where VCN will be created.
ssh_authorized_keys | Public SSH keys path to be included in the `~/.ssh/authorized_keys` file for the default user on the instance.
ssh_private_key | Private key path to access the instance.
slurm_version | The version of the Slurm, by default is 18.08.4
control_ad  | The name of the Slurm Control node instance.
control_subnet_id | The OCID of the Slurm Control subnet to create the VNIC in.
control_display_name | The name of the Slurm Control node instance.
control_image_id | OCID of an image for a control instance to use. For more information, see [Oracle Cloud Infrastructure: Images](https://docs.cloud.oracle.com/iaas/images/).
control_shape | Shape to be used on the control instance.
control_user_data | Provide your own base64-encoded data to be used by `Cloud-Init` to run custom scripts or provide custom `Cloud-Init` configuration for control instance.
compute_count | Number of compute instances to launch.
compute_ads | List of availability domains for Slurm compute.
compute_subnet_ids | List of Slurm compute subnet IDs.
compute_display_name | Name of the compute instance.
compute_image_id | OCID of an image for use by the compute instance. For more information, see see [Oracle Cloud Infrastructure: Images](https://docs.cloud.oracle.com/iaas/images/).
compute_shape | Shape to be used on the compute instance.
bastion_host | The bastion host IP.
bastion_user | The SSH user to connect to the bastion host, by default is opc.
bastion_private_key | The private key path to access the bastion host.
