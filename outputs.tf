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
  description = "Complete deployment configuration summary"
  value = {
    # Database configuration
    adb_tier = var.use_always_free_adb ? "Always Free ADB" : "Payable ADB"
    adb_cpu_cores = local.actual_adb_cpu_cores
    adb_storage_gb = local.actual_adb_storage_gb
    adb_auto_scaling = var.use_always_free_adb ? "Not Available" : (var.adb_auto_scaling_enabled ? "Enabled" : "Disabled")
    adb_max_cpu_cores = var.use_always_free_adb ? "N/A" : (var.adb_auto_scaling_enabled ? var.adb_auto_scaling_max_cpu_core_count : "N/A")
    
    # Compute configuration
    compute_tier = var.use_always_free_compute ? "Always Free Compute" : "Custom Compute"
    compute_shape = local.actual_instance_shape
    compute_specs = var.use_always_free_compute ? "1 OCPU, 1GB RAM" : "${var.instance_ocpus} OCPUs, ${var.instance_memory_gb}GB RAM"
    
    # Database details
    db_version = var.adb_version
    db_workload = var.adb_workload
    
    # Python environment
    python_driver = "python-oracledb (modern successor to cx_Oracle)"
    pre_installed_packages = "oracledb, flask, pandas, numpy, jupyter, matplotlib, seaborn"
  }
}

output "cost_estimation" {
  description = "Cost estimation based on configuration"
  value = {
    monthly_cost = var.use_always_free_adb && var.use_always_free_compute ? "$0/month (Always Free)" : var.use_always_free_adb ? "~$10-50/month (Free ADB + Custom Compute)" : var.use_always_free_compute ? "~$50-200/month (Custom ADB + Free Compute)" : "Variable (Custom ADB + Custom Compute)"
    adb_cost = var.use_always_free_adb ? "Free (Always Free tier)" : "Variable based on CPU/storage usage"
    compute_cost = var.use_always_free_compute ? "Free (Always Free tier)" : "Variable based on shape and usage"
    note = "Actual costs may vary based on usage patterns and region. Check OCI pricing calculator for precise estimates."
  }
}

output "resource_summary" {
  description = "Summary of all deployed resources"
  value = {
    # Core resources
    autonomous_database = "${var.resource_prefix}-adb"
    compute_instance = "${var.resource_prefix}-instance"
    vcn = "${var.resource_prefix}-vcn"
    
    # Network configuration
    networking = "VCN with public subnet, Internet Gateway, Security Lists"
    open_ports = "SSH (22), HTTP (80), HTTPS (443), Flask (5000), Jupyter (8888)"
    
    # Database access
    database_admin_user = "ADMIN"
    database_service_names = "${var.db_name}_high, ${var.db_name}_medium, ${var.db_name}_low"
    
    # Development environment
    python_version = "Python 3 (latest from Oracle Linux)"
    oracle_driver = "python-oracledb (Thin mode - no Oracle Client libraries needed)"
    development_tools = "Flask, Jupyter Notebook, pandas, numpy, matplotlib"
  }
}

# ===================================================================
# SETUP INSTRUCTIONS
# ===================================================================

output "setup_instructions" {
  description = "Complete step-by-step setup guide"
  value = <<-EOT
  🚀 DEPLOYMENT COMPLETED SUCCESSFULLY!
  
  📋 CONFIGURATION SUMMARY:
  • Database: ${var.use_always_free_adb ? "Always Free ADB (1 CPU, 20GB)" : "Payable ADB (${var.adb_cpu_core_count} CPUs, ${var.adb_data_storage_size_in_gb}GB)"}
  • Compute: ${var.use_always_free_compute ? "Always Free (VM.Standard.E2.1.Micro)" : "Custom (${var.instance_shape})"}
  • Python Driver: python-oracledb (modern, no Oracle Client needed)
  • Cost: ${var.use_always_free_adb && var.use_always_free_compute ? "$0/month" : "Variable (see cost estimation)"}
  
  🔗 NEXT STEPS:
  
  1️⃣ Connect to your instance:
     ssh opc@${oci_core_instance.compute_instance.public_ip}
  
  2️⃣ Download database wallet:
     • Go to OCI Console → Autonomous Database
     • Click "${var.resource_prefix}-adb" → DB Connection
     • Download Wallet → Save as wallet.zip
  
  3️⃣ Upload wallet to instance:
     scp wallet.zip opc@${oci_core_instance.compute_instance.public_ip}:
  
  4️⃣ Extract wallet and test connection:
     ssh opc@${oci_core_instance.compute_instance.public_ip}
     unzip wallet.zip -d wallet/
     python3 test_connect.py
  
  📊 DATABASE CONNECTION INFO:
     • Admin User: ADMIN
     • Password: [The password you provided]
     • Service Names:
       - ${var.db_name}_high (best performance)
       - ${var.db_name}_medium (balanced)
       - ${var.db_name}_low (lowest cost)
  
  🐍 PYTHON EXAMPLES READY TO USE:
     • test_connect.py - Test database connectivity
     • connection_example.py - Basic python-oracledb template
     • flask_example.py - Web application (http://${oci_core_instance.compute_instance.public_ip}:5000)
     • jupyter_oracle_example.py - Data analysis template
  
  🌐 WEB ACCESS ENABLED:
     • HTTP: http://${oci_core_instance.compute_instance.public_ip}
     • HTTPS: https://${oci_core_instance.compute_instance.public_ip}
     • Flask Dev: http://${oci_core_instance.compute_instance.public_ip}:5000
     • Jupyter: http://${oci_core_instance.compute_instance.public_ip}:8888
  
  📦 PRE-INSTALLED PACKAGES:
     • oracledb - Modern Oracle database driver
     • flask - Web framework
     • pandas, numpy - Data analysis
     • jupyter - Interactive notebooks
     • matplotlib, seaborn - Data visualization
  
  💡 PYTHON-ORACLEDB ADVANTAGES:
     • Thin Mode: No Oracle Client libraries needed
     • Modern API: Successor to cx_Oracle
     • Better Performance: Optimized for cloud
     • Easy Migration: Drop-in replacement for most cx_Oracle code
  
  📍 DEPLOYMENT DETAILS:
     • Region: ${var.region}
     • Compartment: Current compartment (auto-selected)
     • Database Version: ${var.adb_version}
     • Created: ${timestamp()}
  
  ${var.use_always_free_adb && var.use_always_free_compute ? "✅ ALWAYS FREE: No charges for this deployment!" : "💰 BILLING ACTIVE: Monitor usage in OCI Console"}
  
  🆘 NEED HELP?
     • Check logs: sudo cat /var/log/oracle-setup.log
     • Test python-oracledb: python3 -c "import oracledb; print(oracledb.__version__)"
     • Verify wallet: ls -la wallet/
  EOT
}

# ===================================================================
# TECHNICAL DETAILS (for automation/integration)
# ===================================================================

output "resource_ocids" {
  description = "OCIDs of all created resources"
  value = {
    compartment_id         = local.current_compartment_id
    vcn_id                 = oci_core_vcn.vcn.id
    subnet_id              = oci_core_subnet.public_subnet.id
    instance_id            = oci_core_instance.compute_instance.id
    autonomous_database_id = oci_database_autonomous_database.adb.id
    internet_gateway_id    = oci_core_internet_gateway.ig.id
    route_table_id         = oci_core_route_table.public_rt.id
    security_list_id       = oci_core_security_list.public_sl.id
  }
}

output "database_endpoints" {
  description = "Database connection endpoints"
  value = oci_database_autonomous_database.adb.connection_urls
  sensitive = false
}

output "deployment_metadata" {
  description = "Deployment metadata for tracking and automation"
  value = {
    # Configuration flags
    always_free_adb = var.use_always_free_adb
    always_free_compute = var.use_always_free_compute
    
    # Resource configuration
    resource_prefix = var.resource_prefix
    database_name = var.db_name
    database_workload = var.adb_workload
    database_version = var.adb_version
    
    # Capacity configuration
    adb_cpu_cores = local.actual_adb_cpu_cores
    adb_storage_gb = local.actual_adb_storage_gb
    adb_auto_scaling = var.use_always_free_adb ? false : var.adb_auto_scaling_enabled
    
    compute_shape = local.actual_instance_shape
    compute_ocpus = var.use_always_free_compute ? 1 : var.instance_ocpus
    compute_memory_gb = var.use_always_free_compute ? 1 : var.instance_memory_gb
    
    # Technical details
    python_driver = "python-oracledb"
    deployment_time = timestamp()
    terraform_version = ">=1.0"
    stack_version = "3.0"
  }
}