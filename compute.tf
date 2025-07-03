resource "oci_core_instance" "vm" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  shape               = local.compute_shape

  shape_config {
    ocpus         = local.compute_ocpus
    memory_in_gbs = local.compute_memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.latest.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
    user_data           = filebase64("${path.module}/cloud-init.yaml")
  }
}
