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

############################################
# Create Security List
############################################
resource "oci_core_security_list" "slurmnode" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "slurmcnode"
  vcn_id         = "${oci_core_virtual_network.slurmvcn.id}"

  egress_security_rules = [{
    destination = "0.0.0.0/0"
    protocol    = "6"
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
  ]
}

############################################
# Create Slurm Control Subnet
############################################
resource "oci_core_subnet" "slurmcontrol" {
  availability_domain = "${data.template_file.ad_names.*.rendered[0]}"
  cidr_block          = "${cidrsubnet("${local.master_subnet_prefix}", 4, 0)}"
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
  cidr_block          = "${cidrsubnet("${local.slave_subnet_prefix}", 4, 1)}"
  display_name        = "slurmcompute"
  dns_label           = "slurmcompute"
  security_list_ids   = ["${oci_core_security_list.slurmnode.id}"]
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.slurmvcn.id}"
  route_table_id      = "${oci_core_route_table.public.id}"
  dhcp_options_id     = "${oci_core_virtual_network.slurmvcn.default_dhcp_options_id}"
}
