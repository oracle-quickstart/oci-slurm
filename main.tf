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
  bastion_host          = "${var.bastion_host}"
  bastion_user          = "${var.bastion_user}"
  bastion_private_key   = "${var.bastion_private_key}"
}

############################################
# Prepare config file
############################################
data "template_file" "config_slurm" {
  template = "${file("${path.module}/scripts/config.sh")}"

  vars = {
    control_ip        = "${module.slurm-control.private_ip}"
    control_hostname  = "${module.slurm-control.host_name}"
    compute_ips       = "${join(",", module.slurm-compute.private_ips)}"
    compute_hostnames = "${join(",", module.slurm-compute.host_names)}"
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
      host        = "${module.slurm-compute.private_ips[count.index]}"
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    source      = "${path.module}/scripts/slurm.conf.tmp"
    destination = "~/slurm.conf.tmp"
  }

  provisioner "file" {
    connection = {
      host        = "${module.slurm-compute.private_ips[count.index]}"
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    content     = "${data.template_file.config_slurm.rendered}"
    destination = "~/config.sh"
  }

  provisioner "remote-exec" {
    connection = {
      host        = "${module.slurm-compute.private_ips[count.index]}"
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = "${file("${var.ssh_private_key}")}"
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
  depends_on = ["null_resource.compute"]

  # Changes to any instance of the compute node requires re-provisioning

  triggers {
    compute_hostnames = "${join(" ", module.slurm-compute.host_names)}"
  }
  provisioner "file" {
    connection = {
      host        = "${module.slurm-control.public_ip}"
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = "${file("${var.ssh_private_key}")}"
    }

    source      = "${path.module}/scripts/slurm.conf.tmp"
    destination = "~/slurm.conf.tmp"
  }
  provisioner "file" {
    connection = {
      host        = "${module.slurm-control.public_ip}"
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = "${file("${var.ssh_private_key}")}"
    }

    content     = "${data.template_file.config_slurm.rendered}"
    destination = "~/config.sh"
  }
  provisioner "remote-exec" {
    connection = {
      host        = "${module.slurm-control.public_ip}"
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = "${file("${var.ssh_private_key}")}"
    }

    inline = [
      "chmod +x ~/config.sh",
      "~/config.sh control",
    ]
  }
}
