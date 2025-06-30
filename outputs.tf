# ===================================================================
# CONNECTION INFORMATION
# ===================================================================

output "instance_public_ip" {
  description = "Public IP address of the compute instance"
  value       = oci_core_instance.compute_instance.public_ip
}

output "ssh_connection_command" {
  description = "Ready-to-use SSH command"
  value       = "ssh opc@${oci_core_instance.compute_instance.public_ip}"
}

output "database_connection_strings" {
  description = "Database service names for connections"
  value = {
    high   = "${var.db_name}_high"
    medium = "${var.db_name}_medium"
    low    = "${var.db_name}_low"
  }
}

# ===================================================================
# DEPLOYMENT SUMMARY
# ===================================================================

output "deployment_tier" {
  description = "Deployment tier information"
  value = {
    tier_type    = var.enable_free_tier ? "Always Free" : "Paid Tier"
    monthly_cost = var.enable_free_tier ? "$0" : "Variable (based on usage)"
    description  = var.enable_free_tier ? "Perfect for development and learning" : "Production-ready resources"
  }
}

output "resource_configuration" {
  description = "Summary of deployed resources"
  value = {
    compute = var.enable_free_tier ? "VM.Standard.E2.1.Micro (1 OCPU, 1GB RAM)" : "${var.compute_shape} (${var.compute_ocpus} OCPUs, ${var.compute_memory_gb}GB RAM)"
    database = var.enable_free_tier ? "1 OCPU, 20GB Storage" : "${var.database_ocpus} OCPUs, ${var.database_storage_tb}TB Storage"
    auto_scaling = var.enable_free_tier ? "Not available" : (var.enable_auto_scaling ? "Enabled" : "Disabled")
    networking = "VCN with public subnet, Internet Gateway"
    web_access = var.enable_web_access ? "HTTP/HTTPS ports open" : "SSH only"
  }
}

output "estimated_monthly_cost" {
  description = "Estimated monthly cost"
  value = var.enable_free_tier ? "✅ $0/month (Always Free tier)" : "💰 Variable cost (paid resources - check OCI pricing calculator)"
}

# ===================================================================
# SETUP INSTRUCTIONS
# ===================================================================

output "setup_instructions" {
  description = "Step-by-step setup guide"
  value = <<-EOT
  🚀 NEXT STEPS:
  
  1️⃣ Connect to your instance:
     ssh opc@${oci_core_instance.compute_instance.public_ip}
  
  2️⃣ Download database wallet:
     • Go to OCI Console → Autonomous Database
     • Click "${var.resource_prefix}-adb" → DB Connection
     • Download Wallet → Save as wallet.zip
  
  3️⃣ Upload wallet to instance:
     scp wallet.zip opc@${oci_core_instance.compute_instance.public_ip}:
  
  4️⃣ Extract and test:
     ssh opc@${oci_core_instance.compute_instance.public_ip}
     unzip wallet.zip -d wallet/
     python3 test_connect.py
  
  📋 DATABASE CONNECTION INFO:
     • Admin User: ADMIN
     • Password: [The password you provided]
     • Service Names:
       - ${var.db_name}_high (best performance)
       - ${var.db_name}_medium (balanced)
       - ${var.db_name}_low (lowest cost)
  
  💡 AVAILABLE SCRIPTS:
     • test_connect.py - Test database connectivity
     • connection_example.py - Basic connection template  
     • flask_example.py - Web application example
  
  ${var.enable_free_tier ? "✅ FREE TIER: No charges for this deployment!" : "💰 PAID TIER: Monitor usage in OCI Console"}
  EOT
}

# ===================================================================
# TECHNICAL DETAILS (for automation/integration)
# ===================================================================

output "resource_ids" {
  description = "OCIDs of created resources"
  value = {
    vcn_id                 = oci_core_vcn.vcn.id
    subnet_id              = oci_core_subnet.public_subnet.id
    instance_id            = oci_core_instance.compute_instance.id
    autonomous_database_id = oci_database_autonomous_database.adb.id
  }
}

output "database_endpoints" {
  description = "Database connection endpoints"
  value = oci_database_autonomous_database.adb.connection_urls
  sensitive = false
}

output "deployment_metadata" {
  description = "Deployment configuration metadata"
  value = {
    free_tier_enabled = var.enable_free_tier
    resource_prefix   = var.resource_prefix
    database_name     = var.db_name
    database_workload = var.database_workload
    web_access_enabled = var.enable_web_access
    deployment_time   = timestamp()
  }
}