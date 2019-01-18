output "id" {
  value = "${oci_core_instance.slurm_auth.id}"
}

output "private_ip" {
  value = "${oci_core_instance.slurm_auth.private_ip}"
}

output "host_name" {
  value = "${oci_core_instance.slurm_auth.display_name}"
}

