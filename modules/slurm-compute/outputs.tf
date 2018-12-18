output "ids" {
  value = ["${oci_core_instance.slurm_compute.*.id}"]
}

output "private_ips" {
  value = ["${oci_core_instance.slurm_compute.*.private_ip}"]
}

output "host_names" {
  value = ["${oci_core_instance.slurm_compute.*.display_name}"]
}
