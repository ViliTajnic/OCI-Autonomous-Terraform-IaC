data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "latest" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = local.compute_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_database_autonomous_database" "adb" {
  compartment_id             = var.compartment_id
  db_name                    = "myadb"
  admin_password             = var.adb_admin_password
  cpu_core_count             = local.adb_cpu_core_count
  data_storage_size_in_tbs   = local.adb_data_storage_size_in_tbs
  db_workload                = "OLTP"
  is_free_tier               = var.use_free_tier
  is_auto_scaling_enabled    = false
}

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
  }
}
