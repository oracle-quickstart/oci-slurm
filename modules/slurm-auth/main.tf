data "template_file" "execution" {
  template = "${file("${path.module}/scripts/setup.sh")}"

  vars {
  }
}

resource "oci_core_instance" "slurm_auth" {
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.auth_display_name}"
  shape               = "${var.shape}"

  create_vnic_details {
    subnet_id        = "${var.subnet_id}"
    display_name     = "${var.auth_display_name}"
    assign_public_ip = "${var.assign_public_ip}"
    hostname_label   = "${var.auth_display_name}"
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
    destination = "~/install_auth.sh"
  }

  provisioner "remote-exec" {

    inline = [
      "chmod +x ~/install_auth.sh",
      "~/install_auth.sh",
    ]
  }
}
