# ------------------------------------------------------------------------------
# Setup Bastion Host
# ------------------------------------------------------------------------------
resource "oci_core_instance" "slurmbastion" {
  availability_domain = "${data.template_file.ad_names.*.rendered[var.bastion_ad_index]}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.bastion_display_name}"
  shape               = "${var.bastion_shape}"

  create_vnic_details {
    subnet_id        = "${oci_core_subnet.slurmbastion.id}"
    assign_public_ip = true
  }

  metadata {
    ssh_authorized_keys = "${file("${var.bastion_authorized_keys}")}"
  }

  source_details {
    source_id   = "${var.image_id[var.region]}"
    source_type = "image"
  }
}

# ------------------------------------------------------------------------------
# Config Bastion Node
# ------------------------------------------------------------------------------
resource "null_resource" "bastion" {

  connection = {
    host        = "${oci_core_instance.slurmbastion.public_ip}"
    agent       = false
    timeout     = "5m"
    user        = "opc"
    private_key = "${file("${var.ssh_private_key}")}"
  }

  provisioner "file" {
    source      = "${var.ssh_private_key}"
    destination = "~/id_rsa_oci"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 ~/id_rsa_oci",
    ]
  }
}

# ------------------------------------------------------------------------------
# DEPLOY THE SLURM CLUSTER
# ------------------------------------------------------------------------------
module "slurm-cluster" {
  source              = "../../"
  compartment_ocid    = "${var.compartment_ocid}"
  ssh_authorized_keys = "${var.ssh_authorized_keys}"
  ssh_private_key     = "${var.ssh_private_key}"
  control_ad          = "${data.template_file.ad_names.*.rendered[0]}"
  control_subnet_id   = "${oci_core_subnet.slurmcontrol.id}"
  control_image_id    = "${var.image_id[var.region]}"
  compute_ad          = "${data.template_file.ad_names.*.rendered[1]}"
  compute_subnet_id   = "${oci_core_subnet.slurmcompute.id}"
  compute_image_id    = "${var.image_id[var.region]}"
  compute_count       = 2 
  bastion_host        = "${oci_core_instance.slurmbastion.public_ip}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
  slurm_fs_ip         = "${data.oci_core_private_ips.IPClusterFSMountTarget.private_ips.0.ip_address}"
  private_key_path    = "${var.private_key_path}"
  enable_nis          = "${var.enable_nis}"
  enable_ldap         = "${var.enable_ldap}"
  auth_subnet_id      = "${oci_core_subnet.NISServerSubnetAD.id}"
}
