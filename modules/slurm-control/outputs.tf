output "id" {
  value = "${oci_core_instance.slurm_control.id}"
}

output "private_ip" {
  value = "${oci_core_instance.slurm_control.private_ip}"
}

output "public_ip" {
  value = "${oci_core_instance.slurm_control.public_ip}"
}


output "host_name" {
  value = "${oci_core_instance.slurm_control.display_name}"
}

