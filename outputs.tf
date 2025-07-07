# Shape selection information
output "selected_shape_info" {
  description = "Information about selected compute shape"
  value = {
    selected_shape    = local.selected_shape
    shape_type        = local.shape_type
    shape_config      = local.shape_config
    availability_domain = local.selected_ad
    preference        = var.preferred_shape
  }
}

# Instance connection information
output "instance_public_ip" {
  description = "Public IP address of the compute instance"
  value       = oci_core_instance.python_instance.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh opc@${oci_core_instance.python_instance.public_ip}"
}

# Database information
output "adb_display_name" {
  description = "Autonomous Database display name"
  value       = oci_database_autonomous_database.python_adb.display_name
}

output "adb_db_name" {
  description = "Autonomous Database name"
  value       = oci_database_autonomous_database.python_adb.db_name
}

output "adb_service_console_url" {
  description = "Autonomous Database service console URL"
  value       = oci_database_autonomous_database.python_adb.service_console_url
}

output "database_connection_info" {
  description = "Database connection information"
  value = {
    db_name      = local.adb_db_name
    service_high = "${lower(local.adb_db_name)}_high"
    service_med  = "${lower(local.adb_db_name)}_medium"
    service_low  = "${lower(local.adb_db_name)}_low"
  }
}

# Network information
output "vcn_id" {
  description = "VCN OCID"
  value       = oci_core_vcn.python_vcn.id
}

output "subnet_id" {
  description = "Subnet OCID"
  value       = oci_core_subnet.python_subnet.id
}

# Resource IDs
output "resource_ids" {
  description = "OCIDs of all created resources"
  value = {
    compartment_id = local.current_compartment_id
    vcn_id         = oci_core_vcn.python_vcn.id
    subnet_id      = oci_core_subnet.python_subnet.id
    adb_id         = oci_database_autonomous_database.python_adb.id
    instance_id    = oci_core_instance.python_instance.id
  }
}

# Demo guidance
output "next_steps" {
  description = "What to do after deployment"
  value = [
    "1. SSH to instance: ssh opc@${oci_core_instance.python_instance.public_ip}",
    "2. Go to OCI Console → Oracle Database → Autonomous Database",
    "3. Click '${local.adb_display_name}' → DB Connection",
    "4. Download Wallet → Set password → Save as wallet.zip",
    "5. Upload wallet: scp wallet.zip opc@${oci_core_instance.python_instance.public_ip}:",
    "6. Extract wallet: unzip wallet.zip -d wallet/",
    "7. Test connection: python3 test_connect.py"
  ]
}

# Cost information
output "cost_info" {
  description = "Cost information"
  value = var.use_free_tier ? "This stack uses Always Free tier resources - Total cost: $0/month" : "This stack uses PAID tier resources - Check OCI billing for costs"
}

# Database tier info
output "database_tier_info" {
  description = "Database tier information"
  value = {
    tier               = var.use_free_tier ? "Always Free" : "Paid"
    cpu_cores          = local.adb_cpu_cores
    storage_tbs        = local.adb_storage
    auto_scaling       = var.use_free_tier ? false : var.adb_auto_scaling_enabled
  }
}