resource "oci_core_instance" "slurm_auth" {
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.auth_display_name}"
  shape               = "${var.shape}"

  create_vnic_details {
    subnet_id        = "${var.subnet_id}"
    display_name     = "${var.auth_display_name}"
    assign_public_ip = "${var.assign_public_ip}"
    hostname_label   = "${var.auth_display_name}"
  }

  metadata {
    ssh_authorized_keys = "${file("${var.ssh_authorized_keys}")}"
  }

  source_details {
    source_id   = "${var.image_id}"
    source_type = "image"
  }

  timeouts {
    create = "5m"
  }
}

data "oci_core_subnet" "server_subnet" {
  subnet_id = "${var.subnet_id}"
}

# ---------------------------------------------------------------------------------------------------------------------
# SETUP THE NIS
# ---------------------------------------------------------------------------------------------------------------------
module "setup_nis" {
  source                         = "./nis/instance-configure"
  nis_login_host_public_ip       = "${var.bastion_host}"
  nis_login_user                 = "${var.bastion_user}"
  nis_login_host_ssh_private_key = "${var.bastion_private_key}"
  nis_server_hostname            = "${oci_core_instance.slurm_auth.display_name}"
  nis_server_domainname          = "${data.oci_core_subnet.server_subnet.subnet_domain_name}"
  nis_domain_name                = "${var.nis_domain_name}"
  nis_server_private_ip          = "${oci_core_instance.slurm_auth.private_ip}"
  nis_server_user                = "${var.nis_server_user}"
  nis_server_ssh_private_key     = "${var.ssh_private_key}"
  nis_server_sercure_net_list    = "${var.nis_server_sercure_net_list}"
  control_private_ip             = "${var.control_private_ip}"
  compute_node_private_ips       = "${var.compute_node_private_ips}"
  nis_client_private_user        = "${var.ssh_user}"
  nis_client_ssh_private_key     = "${var.ssh_private_key}"
  nis_sudo_group_name            = "${var.nis_sudo_group_name}"
  compute_count                  = "${var.compute_count}"
}
