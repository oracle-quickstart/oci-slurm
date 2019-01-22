############################################
# Create VCN
############################################
resource "oci_core_virtual_network" "slurmvcn" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "slurmvcn"
  cidr_block     = "${var.vcn_cidr}"
  dns_label      = "slurmvcn"
}

############################################
# Create Internet Gateway
############################################
resource "oci_core_internet_gateway" "slurmig" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.slurmvcn.id}"
  display_name   = "slurmig"
}

############################################
# Create NAT Gateway
############################################
resource "oci_core_nat_gateway" "slurmng" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.slurmvcn.id}"
  display_name   = "slurmng"
}

############################################
# Create Route Table
############################################
resource "oci_core_route_table" "public" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.slurmvcn.id}"
  display_name   = "public"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.slurmig.id}"
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.slurmvcn.id}"
  display_name   = "private"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = "${oci_core_nat_gateway.slurmng.id}"
  }
}


############################################
# Create Security List
############################################
resource "oci_core_security_list" "slurmnat" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "slurmnat"
  vcn_id         = "${oci_core_virtual_network.slurmvcn.id}"

  egress_security_rules = [{
    protocol    = "6"
    destination = "0.0.0.0/0"
  }]

  ingress_security_rules = [{
    protocol = "6"
    source   = "${var.vcn_cidr}"
  }]
}


resource "oci_core_security_list" "slurmnode" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "slurmcnode"
  vcn_id         = "${oci_core_virtual_network.slurmvcn.id}"

  egress_security_rules = [{
    protocol    = "6"
    destination = "0.0.0.0/0"
  }]

  ingress_security_rules = [{
    tcp_options {
      "max" = 22
      "min" = 22
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  },
    {
      tcp_options {
        "max" = "6819"
        "min" = "6817"
      }

      protocol = "6"
      source   = "0.0.0.0/0"
    },
    {
      tcp_options {
        "max" = "7312"
        "min" = "7312"
      }

      protocol = "6"
      source   = "0.0.0.0/0"
    },
    {
      tcp_options {
        "max" = "63000"
        "min" = "60001"
      }

      protocol = "6"
      source   = "0.0.0.0/0"
    },
    {
      tcp_options {
        "max" = "2050"
        "min" = "2048"
      }
      protocol = "6"
      source   = "0.0.0.0/0"
    },
    {
      tcp_options {
        "max" = "111"
        "min" = "111"
      }
      protocol = "6"
      source   = "0.0.0.0/0"
    },
    {
      udp_options {
        "max" = "111"
        "min" = "111"
      }
      protocol = "17"
      source   = "0.0.0.0/0"
    },
    {
      udp_options {
        "max" = "2050"
        "min" = "2048"
      }
      protocol = "17"
      source   = "0.0.0.0/0"
    },
  ]
}

resource "oci_core_security_list" "slurmcomputenode" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "slurmcnode"
  vcn_id         = "${oci_core_virtual_network.slurmvcn.id}"

  egress_security_rules = [{
    protocol    = "6"
    destination = "0.0.0.0/0"
  }]

  ingress_security_rules = [{
    tcp_options {
      "max" = 22
      "min" = 22
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  },
    {
      tcp_options {
        "max" = "6819"
        "min" = "6817"
      }

      protocol = "6"
      source   = "0.0.0.0/0"
    },
    {
      tcp_options {
        "max" = "7312"
        "min" = "7312"
      }

      protocol = "6"
      source   = "0.0.0.0/0"
    },
    {
      tcp_options {
        "max" = "63000"
        "min" = "60001"
      }

      protocol = "6"
      source   = "0.0.0.0/0"
    },
    {
      tcp_options {
        "max" = "2050"
        "min" = "2048"
      }
      protocol = "6"
      source   = "0.0.0.0/0"
    },
    {
      tcp_options {
        "max" = "111"
        "min" = "111"
      }
      protocol = "6"
      source   = "0.0.0.0/0"
    },
    {
      udp_options {
        "max" = "111"
        "min" = "111"
      }
      protocol = "17"
      source   = "0.0.0.0/0"
    },
    {
      udp_options {
        "max" = "2050"
        "min" = "2048"
      }
      protocol = "17"
      source   = "0.0.0.0/0"
    },
  ]
}


resource "oci_core_security_list" "slurmbastion" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "slurmbastion"
  vcn_id         = "${oci_core_virtual_network.slurmvcn.id}"

  egress_security_rules = [{
    tcp_options {
      "max" = 22
      "min" = 22
    }

    protocol    = "6"
    destination = "${var.vcn_cidr}"
  }]

  ingress_security_rules = [{
    tcp_options {
      "max" = 22
      "min" = 22
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }]
}

############################################
# Create Slurm Control Subnet
############################################
resource "oci_core_subnet" "slurmcontrol" {
  availability_domain = "${data.template_file.ad_names.*.rendered[0]}"
  cidr_block          = "${cidrsubnet("${local.control_subnet_prefix}", 4, 0)}"
  display_name        = "slurmcontrol"
  dns_label           = "slurmcontrol"
  security_list_ids   = ["${oci_core_security_list.slurmnode.id}"]
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.slurmvcn.id}"
  route_table_id      = "${oci_core_route_table.public.id}"
  dhcp_options_id     = "${oci_core_virtual_network.slurmvcn.default_dhcp_options_id}"
}

############################################
# Create Slurm Compute node(s) Subnet
############################################
resource "oci_core_subnet" "slurmcompute" {
  availability_domain = "${data.template_file.ad_names.*.rendered[1]}"
  cidr_block          = "${cidrsubnet("${local.compute_subnet_prefix}", 4, 0)}"
  display_name        = "slurmcompute"
  dns_label           = "slurmcompute"
  security_list_ids   = ["${oci_core_security_list.slurmcomputenode.id}"]
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.slurmvcn.id}"
  route_table_id      = "${oci_core_route_table.private.id}"
  dhcp_options_id     = "${oci_core_virtual_network.slurmvcn.default_dhcp_options_id}"
}

############################################
# Create Bastion Subnet
############################################
resource "oci_core_subnet" "slurmbastion" {
  availability_domain = "${data.template_file.ad_names.*.rendered[var.bastion_ad_index]}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "slurmbastion"
  cidr_block          = "${cidrsubnet(local.bastion_subnet_prefix, 4, 0)}"
  security_list_ids   = ["${oci_core_security_list.slurmbastion.id}"]
  vcn_id              = "${oci_core_virtual_network.slurmvcn.id}"
  route_table_id      = "${oci_core_route_table.public.id}"
  dhcp_options_id     = "${oci_core_virtual_network.slurmvcn.default_dhcp_options_id}"
}
