output "slurm_control_public_ip" {
  value = "${module.slurm-cluster.control_private_ip}"
}

output "slurm_compute_private_ip" {
  value = "${module.slurm-cluster.compute_node_private_ips}"
}


output "bastion_public_ip" {
  value = "${oci_core_instance.slurmbastion.public_ip}"
}

output "example_ssh_command" {
  value = "ssh -i ${var.ssh_private_key} -o ProxyCommand=\"ssh -i ${var.bastion_private_key} opc@${oci_core_instance.slurmbastion.public_ip} -W %h:%p\" opc@${module.slurm-cluster.control_private_ip}"
}