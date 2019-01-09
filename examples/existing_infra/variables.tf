variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}
variable "ssh_authorized_keys" {}
variable "ssh_private_key" {}

variable "vcn_cidr" {
  default = "10.0.0.0/16"
}

locals {
  // contains bastion and anything internet-facing
  dmz_tier_prefix = "${cidrsubnet("${var.vcn_cidr}", 2, 0)}"

  // contains private subnets with app logic
  app_tier_prefix = "${cidrsubnet("${var.vcn_cidr}", 2, 1)}"

  bastion_subnet_prefix = "${cidrsubnet("${local.dmz_tier_prefix}", 2, 0)}"
  control_subnet_prefix  = "${cidrsubnet("${local.dmz_tier_prefix}", 2, 1)}"

  compute_subnet_prefix   = "${cidrsubnet("${local.app_tier_prefix}", 2, 0)}"
}

variable "label_prefix" {
  default = ""
}

variable "image_id" {
  type = "map"

  # --------------------------------------------------------------------------
  # Oracle-provided image "Oracle-Linux-7.4-2018.02.21-1"
  # See https://docs.us-phoenix-1.oraclecloud.com/images/
  # --------------------------------------------------------------------------
  default = {
    us-phoenix-1   = "ocid1.image.oc1.phx.aaaaaaaaupbfz5f5hdvejulmalhyb6goieolullgkpumorbvxlwkaowglslq"
    us-ashburn-1   = "ocid1.image.oc1.iad.aaaaaaaajlw3xfie2t5t52uegyhiq2npx7bqyu4uvi2zyu3w3mqayc2bxmaa"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaa7d3fsb6272srnftyi4dphdgfjf6gurxqhmv6ileds7ba3m2gltxq"
    uk-london-1    = "ocid1.image.oc1.uk-london-1.aaaaaaaaa6h6gj6v4n56mqrbgnosskq63blyv2752g36zerymy63cfkojiiq"
  }
}

variable "subnet_id" {
  description = "The subnet id to host the PBS Pro cluster."
}

variable "bastion_display_name" {
  default = "slurmbastion"
}

variable "bastion_shape" {
  default = "VM.Standard2.1"
}

variable "bastion_host" {
  default = ""
}

variable "bastion_user" {
  default = "opc"
}

variable "bastion_authorized_keys" {}
variable "bastion_private_key" {}

variable "bastion_ad_index" {
  default = 2
}
