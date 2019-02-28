variable "tenancy_id" {}
variable "user_id" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "ssh_private_key" {}
variable "bastion_host" { default = "129.146.108.33" }
variable "bastion_user" { default = "opc" }
variable "bastion_private_key" {}

variable "compartment_id" {}

variable "ssh_authorized_keys" {
  default = "~/.ssh/id_rsa.pub"
}

variable "execution_shape" {
  default = "VM.Standard2.1"
}

variable "execution_subnet_name" {
  default = "slurmcompute"
}

variable "execution_vcn_name" {
  default = "slurmvcn"
}

variable "scale_num" {
  default = 1
}

variable "extended_host_display_names" {
  default = {
    "0" = "slurmcompute5"
    "1" = "slurmcompute6"
  }
}

provider "oci" {
  tenancy_ocid         = "${var.tenancy_id}"
  user_ocid            = "${var.user_id}"
  fingerprint          = "${var.fingerprint}"
  private_key_path     = "${var.private_key_path}"
  region               = "${var.region}"
  disable_auto_retries = "true"
}

data "oci_identity_availability_domains" "ad" {
  compartment_id = "${var.tenancy_id}"
}

data "template_file" "ads" {
  count    = "${length(data.oci_identity_availability_domains.ad.availability_domains)}"
  template = "${lookup(data.oci_identity_availability_domains.ad.availability_domains[count.index], "name")}"
}

data "oci_core_images" "execution_image" {
  compartment_id = "${var.compartment_id}"

  filter {
    name   = "display_name"
    values = ["slurmcompute"]
  }
}

data "oci_core_vcns" "cluster_vnc" {
  compartment_id = "${var.compartment_id}"

  filter {
    name   = "display_name"
    values = ["${var.execution_vcn_name}"]
  }
}

data "oci_core_subnets" "cluster_subnet" {
  compartment_id = "${var.compartment_id}"
  vcn_id         = "${data.oci_core_vcns.cluster_vnc.virtual_networks.0.id}"

  filter {
    name   = "display_name"
    values = ["${var.execution_subnet_name}"]
  }
}

resource "oci_core_instance" "extend_host" {
  count = "${var.scale_num}"

  availability_domain = "${data.oci_core_subnets.cluster_subnet.subnets.0.availability_domain}"
  compartment_id      = "${var.compartment_id}"
  display_name        = "${lookup(var.extended_host_display_names,count.index)}"
  shape               = "${var.execution_shape}"

  create_vnic_details {
    subnet_id        = "${data.oci_core_subnets.cluster_subnet.subnets.0.id}"
    assign_public_ip = "false"
  }

  metadata {
    ssh_authorized_keys = "${file("${var.ssh_authorized_keys}")}"
  }

  source_details {
    source_id   = "${data.oci_core_images.execution_image.images.0.id}"
    source_type = "image"
  }

  timeouts {
    create = "10m"
  }
}

resource "null_resource" "compute" {
  depends_on = ["oci_core_instance.extend_host"]
  count = "${var.scale_num}"

  provisioner "file" {
    connection = {
      host                = "${oci_core_instance.extend_host.*.private_ip[count.index]}"
      agent               = false
      timeout             = "5m"
      user                = "opc"
      private_key         = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    source      = "/etc/hosts"
    destination = "~/hosts"
  }
  provisioner "remote-exec" {
    connection = {
      host                = "${oci_core_instance.extend_host.*.private_ip[count.index]}"
      agent               = false
      timeout             = "5m"
      user                = "opc"
      private_key         = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"

    }

    inline = [
      "sudo sleep ${count.index}",
      "sudo chmod 777 /etc/hosts",
      "sudo sed -i '/slurmcompute/d' /etc/hosts",
      "sudo cat hosts | grep control >> /etc/hosts",
      "sudo chmod 777 /mnt/shared/apps/slurm/slurm.conf",
      "sudo sed -i '/${lookup(var.extended_host_display_names,count.index)}/d' /mnt/shared/apps/slurm/slurm.conf",
      "sudo echo 'NodeName=${lookup(var.extended_host_display_names,count.index)} NodeAddr=${oci_core_instance.extend_host.*.private_ip[count.index]} CPUs=2 State=UNKNOWN' >> /mnt/shared/apps/slurm/slurm.conf",
      "sudo systemctl restart slurmd.service",
      "sudo chmod 777  /mnt/shared/apps/slurm",
      "sudo echo '${oci_core_instance.extend_host.*.private_ip[count.index]} ${lookup(var.extended_host_display_names,count.index)}.slurmcompute.slurmvcn.oraclevcn.com ${lookup(var.extended_host_display_names,count.index)}'  > /mnt/shared/apps/slurm/${lookup(var.extended_host_display_names,count.index)}"
    ]
  }
}

output "Extended_Host_Names" {
  value = ["${oci_core_instance.extend_host.*.display_name}"]
}

output "Extended_Host_Private_IPs" {
  value = ["${oci_core_instance.extend_host.*.private_ip}"]
}
