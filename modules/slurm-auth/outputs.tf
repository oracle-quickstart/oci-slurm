output "id" {
  value = "${oci_core_instance.slurm_auth.id}"
}

output "private_ip" {
  value = "${oci_core_instance.slurm_auth.private_ip}"
}

output "host_name" {
  value = "${oci_core_instance.slurm_auth.display_name}"
}

output "server_private_ip" {
  value = "${oci_core_instance.slurm_auth.private_ip}"
}

output "nis_client_private_ip_list" {
  value = ["${var.control_private_ip}", "${var.compute_node_private_ips}"]
}
