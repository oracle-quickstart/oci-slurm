data "template_file" "execution" {
  template = "${file("${path.module}/scripts/setup.sh")}"

  vars {
    slurm_version = "${var.slurm_version}"
  }
}

data "template_file" "dbconfig" {
  template = "${file("${path.module}/scripts/slurmdbd.conf.tmp")}"
}

resource "oci_core_instance" "slurm_control" {
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.control_display_name}"
  shape               = "${var.shape}"

  create_vnic_details {
    subnet_id        = "${var.subnet_id}"
    display_name     = "${var.control_display_name}"
    assign_public_ip = "${var.assign_public_ip}"
    hostname_label   = "${var.control_display_name}"
  }

  metadata {
    ssh_authorized_keys = "${file("${var.ssh_authorized_keys}")}"
  }

  source_details {
    source_id   = "${var.image_id}"
    source_type = "image"
  }

  timeouts {
    create = "10m"
  }

  provisioner "file" {
    connection = {
      host        = "${self.private_ip}"
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    content     = "${data.template_file.execution.rendered}"
    destination = "~/install_slurm.sh"
  }

  provisioner "file" {
    connection = {
      host        = "${self.private_ip}"
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    content     = "${data.template_file.dbconfig.rendered}"
    destination = "~/slurmdbd.conf.tmp"
  }

  provisioner "remote-exec" {
    connection = {
      host        = "${self.private_ip}"
      agent       = false
      timeout     = "5m"
      user        = "opc"
      private_key = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    inline = [
      "chmod +x ~/install_slurm.sh",
      "~/install_slurm.sh",
    ]
  }
}
