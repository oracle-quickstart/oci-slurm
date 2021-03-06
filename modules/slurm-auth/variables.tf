variable "compartment_ocid" {
  description = "Compartment's OCID where VCN will be created. "
}

variable "availability_domain" {
  description = "The Availability Domain of the instance. "
  default     = ""
}

variable "slurm_version" {
  description = "The version of the Slurm."
  default     = "18.08.4"
}

variable "auth_display_name" {
  description = "The name of the Slurm auth instance. "
  default     = ""
}

variable "subnet_id" {
  description = "The OCID of the master subnet to create the VNIC in. "
  default     = ""
}

variable "shape" {
  description = "Instance shape to use for auth instance. "
  default     = ""
}

variable "assign_public_ip" {
  description = "Whether the VNIC should be assigned a public IP address."
  default     = true
}

variable "ssh_authorized_keys" {
  description = "Public SSH keys path to be included in the ~/.ssh/authorized_keys file for the default user on the instance. "
  default     = ""
}

variable "ssh_private_key" {
  description = "The private key path to access instance. "
  default     = ""
}

variable "ssh_user" {
  description = "The user to access instance. "
  default     = "opc"
}

variable "image_id" {
  description = "The OCID of an image for an instance to use. "
  default     = ""
}

variable "user_data" {
  description = "A User Data script to execute while the server is booting."
}

variable "bastion_host" {
  description = "The bastion host IP."
}

variable "bastion_user" {
  description = "The SSH user to connect to the bastion host."
  default     = "opc"
}

variable "bastion_private_key" {
  description = "The private key path to access the bastion host."
}

variable "slurm_fs_ip" {
  default = ""
}

variable "nis_server_user" {
  default = "opc"
}

variable "nis_domain_name" {
  default = "nis.oci.com"
}

variable "nis_sudo_group_name" {
  default = "sudogroup"
}

variable "nis_server_sercure_net_list" {
  type    = "list"
  default = []
}

variable "enable_nis" {
  default = "true"
}

variable "enable_ldap" {
  default = "false"
}

variable "control_private_ip" {}

variable "compute_node_private_ips" {
  type = "list"
}

variable "compute_count" {
  description = "Number of compute instances to launch. "
  default     = 2
}
