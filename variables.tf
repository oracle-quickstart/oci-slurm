variable "compartment_ocid" {
  description = "Compartment's OCID where VCN will be created. "
}

variable "ssh_authorized_keys" {
  description = "Public SSH keys path to be included in the ~/.ssh/authorized_keys file for the default user on the instance. "
  default     = ""
}

variable "ssh_private_key" {
  description = "The private key path to access instance. "
  default     = ""
}

variable "control_ad" {
  description = "The Availability Domain for Slurm control. "
  default     = ""
}

variable "control_subnet_id" {
  description = "The OCID of the control subnet to create the VNIC in. "
  default     = ""
}

variable "control_display_name" {
  description = "The name of the control instance. "
  default     = "slurmcontrol"
}

variable "control_image_id" {
  description = "The OCID of an image for a control instance to use. "
  default     = ""
}

variable "control_shape" {
  description = "Instance shape to use for control instance. "
  default     = "VM.Standard2.1"
}

variable "control_user_data" {
  description = "Provide your own base64-encoded data to be used by Cloud-Init to run custom scripts or provide custom Cloud-Init configuration for control instance. "
  default     = ""
}

variable "compute_count" {
  description = "Number of compute instances to launch. "
  default     = 2 
}

variable "compute_ad" {
  description = "The Availability Domain(s) for Slurm compute(s). "
  default     = ""
}

variable "compute_subnet_id" {
  description = "List of Slurm compute subnets' id. "
  default     = ""
}

variable "compute_display_name" {
  description = "The name of the compute instance. "
  default     = "slurmcompute"
}

variable "compute_image_id" {
  description = "The OCID of an image for compute instance to use.  "
  default     = ""
}

variable "compute_shape" {
  description = "Instance shape to use for compute instance. "
  default     = "VM.Standard2.1"
}

variable "compute_user_data" {
  description = "Provide your own base64-encoded data to be used by Cloud-Init to run custom scripts or provide custom Cloud-Init configuration for compute instance. "
  default     = ""
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
  description = "The fs ip."
}
