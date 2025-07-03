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
