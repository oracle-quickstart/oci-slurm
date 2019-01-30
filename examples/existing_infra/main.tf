provider "oci" {
  tenancy_ocid     = "${var.tenancy_ocid}"
  user_ocid        = "${var.user_ocid}"
  fingerprint      = "${var.fingerprint}"
  private_key_path = "${var.private_key_path}"
  region           = "${var.region}"
}

data "oci_identity_availability_domains" "ad" {
  compartment_id = "${var.tenancy_ocid}"
}

module "slurm-cluster" {
  source              = "../../"
  compartment_ocid    = "${var.compartment_ocid}"
  ssh_authorized_keys = "${var.ssh_authorized_keys}"
  ssh_private_key     = "${var.ssh_private_key}"
  control_ad          = "${lookup(data.oci_identity_availability_domains.ad.availability_domains[var.ad_index - 1], "name")}"
  control_subnet_id   = "${var.subnet_id}"
  control_image_id    = "${var.image_id[var.region]}"
  compute_ad          = "${lookup(data.oci_identity_availability_domains.ad.availability_domains[var.ad_index - 1], "name")}"
  compute_subnet_id   = "${var.subnet_id}"
  compute_image_id    = "${var.image_id[var.region]}"
  compute_count       = 2
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
}
