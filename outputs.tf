output "control_private_ip" {
  value = "${module.slurm-control.private_ip}"
}

output "compute_node_private_ips" {
  value = "${module.slurm-compute.private_ips}"
}
