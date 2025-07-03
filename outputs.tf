output "adb_id" {
  description = "OCID of the Autonomous Database"
  value       = oci_database_autonomous_database.adb.id
}

output "adb_db_name" {
  description = "Database name of the Autonomous Database"
  value       = oci_database_autonomous_database.adb.db_name
}

output "adb_connection_string" {
  description = "First available connection string for Autonomous Database"
  value       = oci_database_autonomous_database.adb.connection_strings[0].all_connection_strings[0]
}

output "compute_instance_id" {
  description = "OCID of the compute instance"
  value       = oci_core_instance.vm.id
}

output "compute_shape" {
  description = "Shape of the compute instance"
  value       = oci_core_instance.vm.shape
}

output "compute_public_ip" {
  description = "Public IP address of the compute instance (if assigned)"
  value       = oci_core_instance.vm.public_ip
}
