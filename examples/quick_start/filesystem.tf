############## FileSystem #######################################################
resource "oci_file_storage_file_system" "TestClusterFS" {
  availability_domain = "${data.template_file.ad_names.*.rendered[0]}" 
  compartment_id      = "${var.compartment_ocid}"
}

resource "oci_file_storage_file_system" "ClusterFSHome" {
  availability_domain = "${data.template_file.ad_names.*.rendered[0]}"
  compartment_id      = "${var.compartment_ocid}"
}


resource "oci_file_storage_mount_target" "TestClusterFSMountTarget" {
  count               = 1
  availability_domain = "${data.template_file.ad_names.*.rendered[0]}" 
  compartment_id      = "${var.compartment_ocid}"
  subnet_id           = "${oci_core_subnet.slurmcontrol.id}"
  display_name        = "fileserverad"
  hostname_label      = "fileserverad"
}

resource "oci_file_storage_export" "TestClusterFSExport" {
  export_set_id  = "${oci_file_storage_mount_target.TestClusterFSMountTarget.export_set_id}"
  file_system_id = "${oci_file_storage_file_system.TestClusterFS.id}"
  path           = "${var.ExportPathFS}"

  export_options {
    source = "0.0.0.0/0"
    access = "READ_WRITE"
    identity_squash = "NONE"
  }
}

resource "oci_file_storage_export" "ClusterFSExportHome" {
  export_set_id  = "${oci_file_storage_mount_target.TestClusterFSMountTarget.export_set_id}"
  file_system_id = "${oci_file_storage_file_system.ClusterFSHome.id}"
  path           = "/UserHome"

  export_options {
    source = "0.0.0.0/0"
    access = "READ_WRITE"
    identity_squash = "NONE"
  }
}

resource "oci_file_storage_export" "ClusterFSExportU01" {
  export_set_id  = "${oci_file_storage_mount_target.TestClusterFSMountTarget.export_set_id}"
  file_system_id = "${oci_file_storage_file_system.TestClusterFS.id}"
  path           = "/u01"

  export_options {
    source = "0.0.0.0/0"
    access = "READ_WRITE"
    identity_squash = "NONE"
  }
}
