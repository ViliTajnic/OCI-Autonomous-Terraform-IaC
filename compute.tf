data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "latest" {
  compartment_id = var.compartment_id
  operating_system = "Oracle Linux"
  operating_system_version = "8"
  shape = var.use_free_tier ? "VM.Standard.A1.Flex" : var.compute_shape
  sort_by = "TIMECREATED"
  sort_order = "DESC"
}

resource "oci_core_instance" "vm" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  shape               = var.use_free_tier ? "VM.Standard.A1.Flex" : var.compute_shape

  shape_config {
    ocpus         = var.use_free_tier ? 1 : var.compute_ocpus
    memory_in_gbs = var.use_free_tier ? 1 : var.compute_memory_in_gbs
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.latest.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
  }
}
