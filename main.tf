############################################
# Setup Slurm Control Node
############################################
module "slurm-control" {
  source               = "./modules/slurm-control"
  availability_domain  = "${var.control_ad}"
  compartment_ocid     = "${var.compartment_ocid}"
  control_display_name = "${var.control_display_name}"
  image_id             = "${var.control_image_id}"
  shape                = "${var.control_shape}"
  subnet_id            = "${var.control_subnet_id}"
  ssh_authorized_keys  = "${var.ssh_authorized_keys}"
  ssh_private_key      = "${var.ssh_private_key}"
  user_data            = "${var.control_user_data}"
  slurm_fs_ip          = "${var.slurm_fs_ip}"
  bastion_host         = "${var.bastion_host}"
  bastion_user         = "${var.bastion_user}"
  bastion_private_key  = "${var.bastion_private_key}"
}

############################################
# Setup Slurm Auth Node
############################################
module "slurm-auth" {
  source                   = "./modules/slurm-auth"
  availability_domain      = "${var.control_ad}"
  compartment_ocid         = "${var.compartment_ocid}"
  auth_display_name        = "${var.auth_display_name}"
  image_id                 = "${var.control_image_id}"
  shape                    = "${var.control_shape}"
  subnet_id                = "${var.auth_subnet_id}"
  ssh_authorized_keys      = "${var.ssh_authorized_keys}"
  ssh_private_key          = "${var.ssh_private_key}"
  user_data                = "${var.control_user_data}"
  bastion_host             = "${var.bastion_host}"
  bastion_user             = "${var.bastion_user}"
  bastion_private_key      = "${var.bastion_private_key}"
  enable_nis               = "${var.enable_nis}"
  enable_ldap              = "${var.enable_ldap}"
  control_private_ip       = "${module.slurm-control.private_ip}"
  compute_node_private_ips = "${module.slurm-compute.private_ips}"
  compute_count            = "${var.compute_count}"
  slurm_fs_ip              = "${var.slurm_fs_ip}"
}

############################################
# Setup Slurm Compute Node(s)
############################################
module "slurm-compute" {
  source               = "./modules/slurm-compute"
  compute_count        = "${var.compute_count}"
  availability_domain  = "${var.compute_ad}"
  compartment_ocid     = "${var.compartment_ocid}"
  slurm_control_ip     = "${module.slurm-control.private_ip}"
  compute_display_name = "${var.compute_display_name}"
  image_id             = "${var.compute_image_id}"
  shape                = "${var.compute_shape}"
  subnet_id            = "${var.compute_subnet_id}"
  ssh_authorized_keys  = "${var.ssh_authorized_keys}"
  ssh_private_key      = "${var.ssh_private_key}"
  user_data            = "${var.compute_user_data}"
  bastion_host         = "${var.bastion_host}"
  bastion_user         = "${var.bastion_user}"
  bastion_private_key  = "${var.bastion_private_key}"
  slurm_fs_ip          = "${var.slurm_fs_ip}"
}

############################################
# Prepare config file
############################################
data "template_file" "config_slurm" {
  template = "${file("${path.module}/scripts/config.sh")}"

  vars = {
    control_ip        = "${module.slurm-control.private_ip}"
    control_hostname  = "${module.slurm-control.host_name}"
    slurm_fs_ip       = "${var.slurm_fs_ip}"
    slurm_bastion_ip  = "${var.bastion_host}"
    compute_ips       = "${join(",", module.slurm-compute.private_ips)}"
    compute_hostnames = "${join(",", module.slurm-compute.host_names)}"
    auth_ip           = "${module.slurm-auth.private_ip}"
    ssh_private_key   = "${var.ssh_private_key}"
  }
}

############################################
# Config Slurm Compute Node(s)
############################################
resource "null_resource" "compute" {
  triggers {
    compute_hostnames = "${join(" ", module.slurm-compute.host_names)}"
  }

  count = "${var.compute_count}"

  provisioner "file" {
    connection = {
      host                = "${module.slurm-compute.private_ips[count.index]}"
      agent               = false
      timeout             = "5m"
      user                = "opc"
      private_key         = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    source      = "${path.module}/scripts/slurm.conf.tmp"
    destination = "~/slurm.conf.tmp"
  }

  provisioner "file" {
    connection = {
      host                = "${module.slurm-compute.private_ips[count.index]}"
      agent               = false
      timeout             = "5m"
      user                = "opc"
      private_key         = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    content     = "${data.template_file.config_slurm.rendered}"
    destination = "~/config.sh"
  }

  provisioner "remote-exec" {
    connection = {
      host                = "${module.slurm-compute.private_ips[count.index]}"
      agent               = false
      timeout             = "5m"
      user                = "opc"
      private_key         = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    inline = [
      "chmod +x ~/config.sh",
      "~/config.sh compute",
    ]
  }
}

############################################
# Config Slurm Control Node
############################################
resource "null_resource" "control" {
  depends_on = ["null_resource.compute","module.slurm-auth"]

  # Changes to any instance of the compute node requires re-provisioning

  triggers {
    compute_hostnames = "${join(" ", module.slurm-compute.host_names)}"
  }
  connection = {
    host                = "${module.slurm-control.private_ip}"
    agent               = false
    timeout             = "10m"
    user                = "opc"
    private_key         = "${file("${var.ssh_private_key}")}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${file("${var.bastion_private_key}")}"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/slurm.conf.tmp"
    destination = "~/slurm.conf.tmp"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/auto_scale_up.tf"
    destination = "~/auto_scale_up.tf"
  }

  provisioner "file" {
    source      = "${path.module}/examples/quick_start/terraform.tfvars"
    destination = "~/terraform.tfvars"
  }

  provisioner "file" {
    source      = "${var.ssh_private_key}"
    destination = "~/.ssh/id_rsa_scale"
  }

  provisioner "file" {
    content     = "${data.template_file.config_slurm.rendered}"
    destination = "~/config.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_terraform.sh"
    destination = "~/install_terraform.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/config.sh",
      "chmod +x ~/install_terraform.sh",
      "~/config.sh control",
      "~/install_terraform.sh",
    ]
  }
}

############################################
# Config Slurm Auth Node
############################################
resource "null_resource" "auth" {
  depends_on = ["null_resource.compute"]

  # Changes to any instance of the compute node requires re-provisioning

  triggers {
    compute_hostnames = "${join(" ", module.slurm-compute.host_names)}"
  }
  connection = {
    host                = "${module.slurm-auth.private_ip}"
    agent               = false
    timeout             = "10m"
    user                = "opc"
    private_key         = "${file("${var.ssh_private_key}")}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${file("${var.bastion_private_key}")}"
  }

  provisioner "file" {
    content     = "${data.template_file.config_slurm.rendered}"
    destination = "~/config.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/config.sh",
      "~/config.sh auth",
    ]
  }
}

resource "oci_core_image" "image" {
  depends_on = ["module.slurm-auth"]

  compartment_id = "${var.compartment_ocid}"
  instance_id = "${module.slurm-compute.ids[0]}"
  display_name = "slurmcompute"
}
