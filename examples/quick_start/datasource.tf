############################################
# Datasource
############################################
# Gets a list of Availability Domains
data "oci_identity_availability_domains" "ad" {
  compartment_id = "${var.compartment_id}"
}

data "template_file" "ad_names" {
  count    = "${length(data.oci_identity_availability_domains.ad.availability_domains)}"
  template = "${lookup(data.oci_identity_availability_domains.ad.availability_domains[count.index], "name")}"
}

data "oci_core_private_ips" IPClusterFSMountTarget {
  count     = 1
  subnet_id = "${oci_core_subnet.slurmcontrol.id}" 

  filter {
    name   = "id"
    values = ["${oci_file_storage_mount_target.TestClusterFSMountTarget.private_ip_ids}"]
  }
}
