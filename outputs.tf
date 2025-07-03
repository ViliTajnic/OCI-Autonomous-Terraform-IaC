# ===================================================================
# CONNECTION INFORMATION
# ===================================================================

output "instance_ip" {
  description = "Public IP of the compute instance"
  value       = oci_core_instance.python_instance.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh opc@${oci_core_instance.python_instance.public_ip}"
}

output "database_name" {
  description = "Database name for connections"
  value       = var.database_name
}

output "connection_strings" {
  description = "Database connection service names"
  value = {
    high   = "${var.database_name}_high"
    medium = "${var.database_name}_medium"
    low    = "${var.database_name}_low"
  }
}

# ===================================================================
# DEPLOYMENT SUMMARY
# ===================================================================

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    tier = var.use_free_tier ? "Always Free ($0/month)" : "Paid Tier (variable cost)"
    
    compute = var.use_free_tier ? "VM.Standard.E2.1.Micro (1 OCPU, 1GB RAM)" : "VM.Standard.E4.Flex (${var.compute_ocpus} OCPUs, ${var.compute_memory_gb}GB RAM)"
    
    database = var.use_free_tier ? "1 CPU core, 20GB storage" : "${var.adb_cpu_cores} CPU cores, ${var.adb_storage_gb}GB storage"
    
    auto_scaling = var.use_free_tier ? "Not available" : (var.enable_auto_scaling ? "Enabled" : "Disabled")
    
    python_driver = "python-oracledb (latest)"
  }
}

output "next_steps" {
  description = "Instructions to get started"
  value = <<-EOT
  🚀 DEPLOYMENT COMPLETE!
  
  Configuration: ${var.use_free_tier ? "Always Free ($0/month)" : "Paid Tier"}
  
  1️⃣ Connect to your instance:
     ${oci_core_instance.python_instance.public_ip}
  
  2️⃣ SSH to the instance:
     ssh opc@${oci_core_instance.python_instance.public_ip}
  
  3️⃣ Download database wallet:
     • Go to OCI Console → Autonomous Database
     • Click "${var.project_name}-adb" → DB Connection
     • Download Wallet → Save as wallet.zip
  
  4️⃣ Upload wallet to instance:
     scp wallet.zip opc@${oci_core_instance.python_instance.public_ip}:
  
  5️⃣ Extract and test:
     ssh opc@${oci_core_instance.python_instance.public_ip}
     unzip wallet.zip -d wallet/
     python3 test_connection.py
  
  📊 DATABASE INFO:
  • Name: ${var.database_name}
  • Admin User: ADMIN
  • Password: [The password you provided]
  • Service Names: ${var.database_name}_high, ${var.database_name}_medium, ${var.database_name}_low
  
  🐍 PYTHON:
  • Driver: python-oracledb (modern, no Oracle Client needed)
  • Examples: test_connection.py, flask_app.py
  • Web access: http://${oci_core_instance.python_instance.public_ip}:5000
  
  ${var.use_free_tier ? "✅ FREE TIER: No charges!" : "💰 PAID TIER: Monitor usage in OCI Console"}
  EOT
}

# ===================================================================
# TECHNICAL DETAILS
# ===================================================================

output "resource_ids" {
  description = "Resource OCIDs for reference"
  value = {
    compartment = var.compartment_ocid
    vcn         = oci_core_vcn.vcn.id
    subnet      = oci_core_subnet.public_subnet.id
    instance    = oci_core_instance.python_instance.id
    database    = oci_database_autonomous_database.adb.id
  }
}