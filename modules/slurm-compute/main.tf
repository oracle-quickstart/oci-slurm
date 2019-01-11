data "template_file" "execution" {
  template = "${file("${path.module}/scripts/setup.sh")}"

  vars = {
    control_ip    = "${var.slurm_control_ip}"
    fs_ip =     "${var.slurm_fs_ip}" 
    slurm_version = "${var.slurm_version}"
  }
}

resource "oci_core_instance" "slurm_compute" {
  count               = "${var.compute_count}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.compute_display_name}${count.index+1}"
  shape               = "${var.shape}"

  create_vnic_details {
    subnet_id        = "${var.subnet_id}"
    display_name     = "${var.compute_display_name}${count.index+1}"
    assign_public_ip = "${var.assign_public_ip}"
    hostname_label   = "${var.compute_display_name}${count.index+1}"
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
    destination = "~/install_slurm_node.sh"
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

    source      = "${var.ssh_private_key}"
    destination = "~/tmp.key"
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
      "chmod 600 ~/tmp.key",
      "chmod +x ~/install_slurm_node.sh",
      "~/install_slurm_node.sh",
    ]
  }
}
