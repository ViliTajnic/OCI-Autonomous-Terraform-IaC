# Instance Connection Details
output "instance_public_ip" {
  description = "Public IP address of the compute instance"
  value       = oci_core_instance.compute_instance.public_ip
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh opc@${oci_core_instance.compute_instance.public_ip}"
}

# Database Information
output "autonomous_database_id" {
  description = "OCID of the Autonomous Database"
  value       = oci_database_autonomous_database.adb.id
}

output "autonomous_database_connection_urls" {
  description = "Connection URLs for the Autonomous Database"
  value       = oci_database_autonomous_database.adb.connection_urls
}

output "database_connection_strings" {
  description = "Database connection strings"
  value = {
    high   = "${var.db_name}_high"
    medium = "${var.db_name}_medium"
    low    = "${var.db_name}_low"
  }
}

# Deployment Configuration
output "deployment_mode" {
  description = "Deployment mode (free_tier or paid_tier)"
  value       = var.use_free_tier ? "free_tier" : "paid_tier"
}

output "resource_summary" {
  description = "Summary of deployed resources"
  value = {
    deployment_mode = var.use_free_tier ? "Always Free Tier" : "Paid Tier"
    compute_shape   = var.use_free_tier ? "VM.Standard.E2.1.Micro" : "${var.instance_shape} (${var.instance_ocpus} OCPUs, ${var.instance_memory_gb} GB RAM)"
    adb_config      = var.use_free_tier ? "1 OCPU, 20 GB" : "${var.adb_cpu_core_count} OCPUs, ${var.adb_storage_tb} TB"
    estimated_cost  = var.use_free_tier ? "$0/month (Always Free)" : "Variable (paid resources)"
  }
}

# Quick Start Instructions
output "quick_start_instructions" {
  description = "Next steps to get started"
  value = <<-EOT
    1. SSH to instance: ssh opc@${oci_core_instance.compute_instance.public_ip}
    2. Download database wallet from OCI Console
    3. Upload wallet: scp wallet.zip opc@${oci_core_instance.compute_instance.public_ip}:
    4. Extract wallet: unzip wallet.zip -d wallet/
    5. Test connection: python3 test_connect.py
    
    Database connection strings:
    - High performance: ${var.db_name}_high
    - Medium performance: ${var.db_name}_medium  
    - Low performance: ${var.db_name}_low
  EOT
}

# Network Details
output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.vcn.id
}

output "public_subnet_id" {
  description = "OCID of the public subnet"
  value       = oci_core_subnet.public_subnet.id
}