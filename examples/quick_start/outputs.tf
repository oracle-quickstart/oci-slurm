output "slurm_control_public_ip" {
  value = "${module.slurm-cluster.control_public_ip}"
}

output "slurm_compute_private_ip" {
  value = "${module.slurm-cluster.compute_node_private_ips}"
}

output "slurm_fs_ip" {
  value = "${data.oci_core_private_ips.IPClusterFSMountTarget.private_ips.0.ip_address}"
}

