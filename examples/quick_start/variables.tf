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
  // contains bastion, LB, and anything internet-facing
  dmz_tier_prefix = "${cidrsubnet("${var.vcn_cidr}", 2, 0)}"

  // contains private subnets with app logic
  app_tier_prefix = "${cidrsubnet("${var.vcn_cidr}", 2, 1)}"

  lb_subnet_prefix      = "${cidrsubnet("${local.dmz_tier_prefix}", 2, 0)}"
  bastion_subnet_prefix = "${cidrsubnet("${local.dmz_tier_prefix}", 2, 1)}"
  master_subnet_prefix  = "${cidrsubnet("${local.app_tier_prefix}", 2, 0)}"
  slave_subnet_prefix   = "${cidrsubnet("${local.app_tier_prefix}", 2, 1)}"
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
