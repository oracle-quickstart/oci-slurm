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
}
