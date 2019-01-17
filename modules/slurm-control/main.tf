data "template_file" "execution" {
  template = "${file("${path.module}/scripts/setup.sh")}"

  vars {
    slurm_fs_ip =     "${var.slurm_fs_ip}" 
    slurm_version = "${var.slurm_version}"
  }
}

data "template_file" "dbconfig" {
  template = "${file("${path.module}/scripts/slurmdbd.conf.tmp")}"
}

data "template_file" "getfsipaddr" {
  template = "${file("${path.module}/scripts/getfsipaddr")}"
}

data "template_file" "installmpi" {
  template = "${file("${path.module}/scripts/installmpi")}"
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

  connection = {
    host        = "${self.private_ip}"
    agent       = false
    timeout     = "10m"
    user        = "opc"
    private_key = "${file("${var.ssh_private_key}")}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${file("${var.bastion_private_key}")}"
  }


  provisioner "file" {

    content     = "${data.template_file.execution.rendered}"
    destination = "~/install_slurm.sh"
  }

  provisioner "file" {

    content     = "${data.template_file.dbconfig.rendered}"
    destination = "~/slurmdbd.conf.tmp"
  }

  provisioner "file" {

    content     = "${data.template_file.getfsipaddr.rendered}"
    destination = "~/getfsipaddr"
  }

  provisioner "file" {

    content     = "${data.template_file.installmpi.rendered}"
    destination = "~/installmpi"
  }

  provisioner "remote-exec" {

    inline = [
      "chmod +x ~/install_slurm.sh",
      "sudo yes \"y\" | ssh-keygen -N \"\" -f ~/.ssh/id_rsa",
      "~/install_slurm.sh",
    ]
  }
}
