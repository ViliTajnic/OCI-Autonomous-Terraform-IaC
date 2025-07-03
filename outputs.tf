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

output "deployment_configuration" {
  description = "Summary of deployment configuration"
  value = {
    adb_tier = var.use_always_free_adb ? "Always Free ADB" : "Payable ADB"
    adb_specs = var.use_always_free_adb ? "1 CPU, 20GB" : "${var.adb_cpu_core_count} CPUs, ${var.adb_data_storage_size_in_gb}GB"
    adb_auto_scaling = var.use_always_free_adb ? "Not Available" : (var.adb_auto_scaling_enabled ? "Enabled (max ${var.adb_auto_scaling_max_cpu_core_count} CPUs)" : "Disabled")
    compute_tier = var.use_always_free_compute ? "Always Free Compute" : "Custom Compute"
    compute_specs = var.use_always_free_compute ? "VM.Standard.E2.1.Micro (1 OCPU, 1GB RAM)" : "${var.instance_shape} (${var.instance_ocpus} OCPUs, ${var.instance_memory_gb}GB RAM)"
    database_version = var.adb_version
    python_driver = "python-oracledb (modern successor to cx_Oracle)"
  }
}

output "cost_estimation" {
  description = "Estimated monthly cost breakdown"
  value = {
    adb_cost = var.use_always_free_adb ? "$0/month (Always Free)" : "Variable (based on usage)"
    compute_cost = var.use_always_free_compute ? "$0/month (Always Free)" : "Variable (based on usage)"
    network_cost = "$0/month (basic networking included)"
    total_estimation = var.use_always_free_adb && var.use_always_free_compute ? "✅ $0/month (Completely Free)" : "💰 Variable cost (monitor usage in OCI Console)"
    cost_optimization_tip = var.use_always_free_adb && var.use_always_free_compute ? "Perfect for development and learning!" : "Consider using Always Free options for development environments"
  }
}

output "resource_summary" {
  description = "Detailed resource configuration"
  value = {
    database = {
      name = var.db_name
      tier = var.use_always_free_adb ? "Always Free" : "Payable"
      cpu_cores = var.use_always_free_adb ? 1 : var.adb_cpu_core_count
      storage_gb = var.use_always_free_adb ? 20 : var.adb_data_storage_size_in_gb
      auto_scaling = var.use_always_free_adb ? false : var.adb_auto_scaling_enabled
      workload_type = var.adb_workload
      version = var.adb_version
    }
    compute = {
      shape = var.use_always_free_compute ? "VM.Standard.E2.1.Micro" : var.instance_shape
      tier = var.use_always_free_compute ? "Always Free" : "Custom"
      ocpus = var.use_always_free_compute ? 1 : var.instance_ocpus
      memory_gb = var.use_always_free_compute ? 1 : var.instance_memory_gb
    }
    networking = {
      ports_open = ["22 (SSH)", "80 (HTTP)", "443 (HTTPS)", "5000 (Flask)", "8888 (Jupyter)"]
      access_type = "Public Internet"
    }
    software = {
      python_driver = "python-oracledb"
      additional_packages = ["pandas", "numpy", "flask", "jupyter", "matplotlib", "seaborn"]
      operating_system = "Oracle Linux 8"
    }
  }
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
  
  💻 PYTHON CONNECTION EXAMPLE:
     import oracledb
     
     connection = oracledb.connect(
         user="ADMIN",
         password="your_password",
         dsn="${var.db_name}_high",
         config_dir="/home/opc/wallet"
     )
  
  🐍 AVAILABLE SCRIPTS:
     • test_connect.py - Test database connectivity
     • connection_example.py - Basic connection template  
     • flask_example.py - Web application example (port 5000)
     • jupyter_oracle_example.py - Data analysis example
  
  🌐 WEB ACCESS:
     • Flask App: http://${oci_core_instance.compute_instance.public_ip}:5000
     • Jupyter: http://${oci_core_instance.compute_instance.public_ip}:8888
  
  📊 YOUR CONFIGURATION:
     • ADB: ${var.use_always_free_adb ? "Always Free (1 CPU, 20GB)" : "Payable (${var.adb_cpu_core_count} CPUs, ${var.adb_data_storage_size_in_gb}GB)"}
     • Compute: ${var.use_always_free_compute ? "Always Free (E2.1.Micro)" : "Custom (${var.instance_shape})"}
     • Auto-scaling: ${var.use_always_free_adb ? "Not Available" : (var.adb_auto_scaling_enabled ? "Enabled" : "Disabled")}
  
  💡 MODERN FEATURES:
     ✅ python-oracledb (latest Oracle driver)
     ✅ Oracle Database 23ai (latest version)
     ✅ Thin mode (no Oracle Client install needed)
     ✅ All web ports open for development
  
  ${var.use_always_free_adb && var.use_always_free_compute ? "✅ COMPLETELY FREE: No charges for this deployment!" : "💰 COST MONITORING: Check OCI Console → Billing for usage"}
  EOT
}

# ===================================================================
# TECHNICAL DETAILS (for automation/integration)
# ===================================================================

output "resource_ids" {
  description = "OCIDs of created resources"
  value = {
    compartment_id         = local.current_compartment_id
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
    adb_free_tier_enabled = var.use_always_free_adb
    compute_free_tier_enabled = var.use_always_free_compute
    resource_prefix = var.resource_prefix
    database_name = var.db_name
    database_workload = var.adb_workload
    database_version = var.adb_version
    python_driver = "python-oracledb"
    deployment_time = timestamp()
    configuration_summary = "${var.use_always_free_adb ? "Free" : "Payable"}_ADB_${var.use_always_free_compute ? "Free" : "Custom"}_Compute"
  }
}# ===================================================================
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
  
  📍 DEPLOYMENT LOCATION:
     • Compartment: Current compartment (auto-selected)
     • Region: ${var.region}
  
  ${var.enable_free_tier ? "✅ FREE TIER: No charges for this deployment!" : "💰 PAID TIER: Monitor usage in OCI Console"}
  EOT
}

# ===================================================================
# TECHNICAL DETAILS (for automation/integration)
# ===================================================================

output "resource_ids" {
  description = "OCIDs of created resources"
  value = {
    compartment_id         = local.current_compartment_id
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