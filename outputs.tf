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
  description = "Database service names for different performance levels"
  value = {
    high   = "${var.db_name}_high"
    medium = "${var.db_name}_medium"
    low    = "${var.db_name}_low"
  }
}

output "database_connection_urls" {
  description = "Complete database connection URLs from Oracle"
  value       = oci_database_autonomous_database.adb.connection_urls
  sensitive   = false
}

output "database_version_info" {
  description = "Information about the selected database version"
  value = {
    selected_version = oci_database_autonomous_database.adb.db_version
    version_note = "Database version automatically selected based on availability"
  }
}

# ===================================================================
# DATABASE CONFIGURATION DETAILS
# ===================================================================

output "database_configuration" {
  description = "Detailed database configuration information"
  value = {
    database_name = var.db_name
    display_name  = oci_database_autonomous_database.adb.display_name
    database_id   = oci_database_autonomous_database.adb.id
    tier_type     = var.use_always_free_adb ? "Always Free" : "Payable"
    
    # Performance specifications
    cpu_cores     = oci_database_autonomous_database.adb.cpu_core_count
    storage_size  = var.use_always_free_adb ? "20GB" : "${var.adb_data_storage_size_in_gb}GB"
    storage_unit  = var.use_always_free_adb ? "GB" : (var.adb_data_storage_size_in_gb > 1024 ? "TB" : "GB")
    
    # Database settings
    db_version    = oci_database_autonomous_database.adb.db_version
    db_workload   = oci_database_autonomous_database.adb.db_workload
    license_model = oci_database_autonomous_database.adb.license_model
    
    # Security settings
    character_set     = "AL32UTF8"
    ncharacter_set    = "AL16UTF16"
    mtls_required     = oci_database_autonomous_database.adb.is_mtls_connection_required
    
    # Auto-scaling configuration
    cpu_auto_scaling     = var.use_always_free_adb ? "Not Available" : (var.adb_auto_scaling_enabled ? "Enabled" : "Disabled")
    storage_auto_scaling = var.use_always_free_adb ? "Not Available" : (var.adb_auto_scaling_for_storage_enabled ? "Enabled" : "Disabled")
    max_cpu_cores       = var.use_always_free_adb ? null : var.adb_auto_scaling_max_cpu_core_count
    
    # Management features (payable tier only)
    database_management = var.use_always_free_adb ? "Not Available" : var.adb_database_management_status
    operations_insights = var.use_always_free_adb ? "Not Available" : var.adb_operations_insights_status
    maintenance_schedule = var.use_always_free_adb ? "Automatic" : var.adb_maintenance_schedule_type
    backup_retention_days = var.use_always_free_adb ? "7 (default)" : "${var.adb_backup_retention_period_in_days} days"
  }
}

# ===================================================================
# COMPUTE INSTANCE DETAILS
# ===================================================================

output "compute_configuration" {
  description = "Compute instance configuration details"
  value = {
    instance_id     = oci_core_instance.compute_instance.id
    display_name    = oci_core_instance.compute_instance.display_name
    tier_type       = var.use_always_free_compute ? "Always Free" : "Custom"
    
    # Performance specifications
    shape           = oci_core_instance.compute_instance.shape
    ocpus          = var.use_always_free_compute ? 1 : var.instance_ocpus
    memory_gb      = var.use_always_free_compute ? 1 : var.instance_memory_gb
    
    # Network configuration
    public_ip      = oci_core_instance.compute_instance.public_ip
    private_ip     = oci_core_instance.compute_instance.private_ip
    hostname       = "pythonhost"
    
    # Connectivity
    ssh_access     = "Port 22"
    web_access     = "Ports 80, 443, 5000, 8888"
    operating_system = "Oracle Linux 8"
  }
}

# ===================================================================
# COST ANALYSIS
# ===================================================================

output "cost_estimation" {
  description = "Detailed cost breakdown and estimation"
  value = {
    # Database costs
    adb_tier = var.use_always_free_adb ? "Always Free" : "Payable"
    adb_cost_estimate = var.use_always_free_adb ? "$0/month (Always Free)" : "~$${ceil(var.adb_cpu_core_count * 25)}-${ceil(var.adb_cpu_core_count * 50)}/month (varies by region and usage)"
    
    # Compute costs  
    compute_tier = var.use_always_free_compute ? "Always Free" : "Payable"
    compute_cost_estimate = var.use_always_free_compute ? "$0/month (Always Free)" : "~$${ceil(var.instance_ocpus * 15)}-${ceil(var.instance_ocpus * 25)}/month (varies by region)"
    
    # Network costs
    network_cost = "$0/month (basic networking included)"
    
    # Total estimation
    total_monthly_estimate = var.use_always_free_adb && var.use_always_free_compute ? "✅ $0/month (Completely Free!)" : "💰 Variable (check OCI Console → Billing for exact costs)"
    
    # Cost optimization tips
    cost_optimization = {
      free_tier_recommendation = var.use_always_free_adb && var.use_always_free_compute ? "Perfect setup for development and learning!" : "Consider Always Free tier for development environments"
      auto_scaling_benefit = var.use_always_free_adb ? null : "Auto-scaling helps optimize costs by scaling down during low usage"
      monitoring_tip = "Use OCI Console → Billing to monitor actual usage and costs"
    }
  }
}

# ===================================================================
# SOFTWARE CONFIGURATION
# ===================================================================

output "software_stack" {
  description = "Software packages and configuration details"
  value = {
    # Python environment
    python_version = "Python 3 (latest from Oracle Linux 8)"
    database_driver = "python-oracledb (modern successor to cx_Oracle)"
    driver_mode = "Thin mode (no Oracle Client libraries required)"
    
    # Pre-installed packages
    python_packages = [
      "oracledb (latest)",
      "pandas (data analysis)", 
      "numpy (numerical computing)",
      "flask (web framework)",
      "jupyter (notebook environment)",
      "matplotlib (plotting)",
      "seaborn (statistical visualization)",
      "sqlalchemy (database toolkit)"
    ]
    
    # Available scripts
    ready_to_use_scripts = {
      "test_connect.py" = "Test database connectivity"
      "connection_example.py" = "Basic connection template"
      "flask_example.py" = "Web application example"
      "jupyter_oracle_example.py" = "Data analysis example"
    }
    
    # Development tools
    development_features = {
      "ssh_access" = "Secure shell access for development"
      "web_ports" = "HTTP/HTTPS/Flask/Jupyter ports open"
      "jupyter_notebook" = "Ready for data science workflows"
      "flask_development" = "Web application development ready"
    }
  }
}

# ===================================================================
# SETUP INSTRUCTIONS
# ===================================================================

output "setup_instructions" {
  description = "Complete step-by-step setup guide"
  value = <<-EOT
  🚀 ORACLE AUTONOMOUS DATABASE + PYTHON SETUP COMPLETE!
  
  ┌─────────────────────────────────────────────────────────────────┐
  │                        QUICK START GUIDE                        │
  └─────────────────────────────────────────────────────────────────┘
  
  1️⃣ CONNECT TO YOUR INSTANCE:
     ssh opc@${oci_core_instance.compute_instance.public_ip}
  
  2️⃣ DOWNLOAD DATABASE WALLET:
     • Go to: OCI Console → Autonomous Database
     • Click: "${oci_database_autonomous_database.adb.display_name}"
     • Click: "DB Connection" button
     • Download Wallet → Save as "wallet.zip"
  
  3️⃣ UPLOAD WALLET TO INSTANCE:
     scp wallet.zip opc@${oci_core_instance.compute_instance.public_ip}:
  
  4️⃣ EXTRACT AND TEST:
     ssh opc@${oci_core_instance.compute_instance.public_ip}
     unzip wallet.zip -d wallet/
     python3 test_connect.py
  
  ┌─────────────────────────────────────────────────────────────────┐
  │                     DATABASE INFORMATION                       │
  └─────────────────────────────────────────────────────────────────┘
  
  📋 CONNECTION DETAILS:
     • Database Name: ${var.db_name}
     • Admin User: ADMIN
     • Password: [The password you provided during deployment]
     • Version: ${oci_database_autonomous_database.adb.db_version}
     • Workload: ${oci_database_autonomous_database.adb.db_workload}
  
  🔗 SERVICE NAMES:
     • High Performance: ${var.db_name}_high
     • Medium Performance: ${var.db_name}_medium
     • Low Performance: ${var.db_name}_low
  
  ┌─────────────────────────────────────────────────────────────────┐
  │                    PYTHON CONNECTION EXAMPLE                   │
  └─────────────────────────────────────────────────────────────────┘
  
  💻 MODERN PYTHON-ORACLEDB CODE:
     import oracledb
     
     # Thin mode - no Oracle Client needed!
     connection = oracledb.connect(
         user="ADMIN",
         password="your_password",
         dsn="${var.db_name}_high",
         config_dir="/home/opc/wallet"
     )
  
  ┌─────────────────────────────────────────────────────────────────┐
  │                      AVAILABLE RESOURCES                       │
  └─────────────────────────────────────────────────────────────────┘
  
  🐍 READY-TO-USE SCRIPTS:
     • test_connect.py → Test database connectivity
     • connection_example.py → Basic connection template  
     • flask_example.py → Web application example
     • jupyter_oracle_example.py → Data analysis example
  
  🌐 WEB ACCESS:
     • Flask Development: http://${oci_core_instance.compute_instance.public_ip}:5000
     • Jupyter Notebook: http://${oci_core_instance.compute_instance.public_ip}:8888
     • Custom Web Apps: http://${oci_core_instance.compute_instance.public_ip}
  
  ┌─────────────────────────────────────────────────────────────────┐
  │                    YOUR CONFIGURATION                          │
  └─────────────────────────────────────────────────────────────────┘
  
  📊 DEPLOYMENT SUMMARY:
     • ADB Tier: ${var.use_always_free_adb ? "Always Free (1 CPU, 20GB)" : "Payable (${var.adb_cpu_core_count} CPUs, ${var.adb_data_storage_size_in_gb}GB)"}
     • Compute: ${var.use_always_free_compute ? "Always Free (E2.1.Micro)" : "Custom (${var.instance_shape})"}
     • Auto-scaling: ${var.use_always_free_adb ? "Not Available" : (var.adb_auto_scaling_enabled ? "Enabled" : "Disabled")}
     • Storage Auto-scaling: ${var.use_always_free_adb ? "Not Available" : (var.adb_auto_scaling_for_storage_enabled ? "Enabled" : "Disabled")}
     • Database Management: ${var.use_always_free_adb ? "Not Available" : var.adb_database_management_status}
  
  ┌─────────────────────────────────────────────────────────────────┐
  │                       MODERN FEATURES                          │
  └─────────────────────────────────────────────────────────────────┘
  
  ✨ LATEST TECHNOLOGY:
     ✅ python-oracledb (latest Oracle driver)
     ✅ Oracle Database ${oci_database_autonomous_database.adb.db_version} (latest version)
     ✅ Thin mode connections (no client install needed)
     ✅ Mutual TLS security (mTLS)
     ✅ Unicode support (AL32UTF8/AL16UTF16)
     ✅ Auto-scaling capabilities${var.use_always_free_adb ? " (upgrade to payable tier)" : ""}
     ✅ All development ports open
  
  ┌─────────────────────────────────────────────────────────────────┐
  │                          COST STATUS                           │
  └─────────────────────────────────────────────────────────────────┘
  
  💰 BILLING: ${var.use_always_free_adb && var.use_always_free_compute ? "✅ COMPLETELY FREE - No charges for this deployment!" : "💰 MONITOR COSTS - Check OCI Console → Billing for usage"}
  
  🎯 SUCCESS! Your Oracle + Python environment is ready for development!
  EOT
}

# ===================================================================
# TECHNICAL DETAILS (for automation/integration)
# ===================================================================

output "resource_ids" {
  description = "OCIDs of all created resources"
  value = {
    compartment_id         = local.current_compartment_id
    vcn_id                 = oci_core_vcn.vcn.id
    subnet_id              = oci_core_subnet.public_subnet.id
    security_list_id       = oci_core_security_list.public_sl.id
    internet_gateway_id    = oci_core_internet_gateway.ig.id
    route_table_id         = oci_core_route_table.public_rt.id
    instance_id            = oci_core_instance.compute_instance.id
    autonomous_database_id = oci_database_autonomous_database.adb.id
  }
}

output "network_configuration" {
  description = "Network configuration details"
  value = {
    vcn_cidr              = "10.0.0.0/16"
    subnet_cidr           = "10.0.1.0/24"
    instance_private_ip   = oci_core_instance.compute_instance.private_ip
    instance_public_ip    = oci_core_instance.compute_instance.public_ip
    open_ports           = ["22 (SSH)", "80 (HTTP)", "443 (HTTPS)", "5000 (Flask)", "8888 (Jupyter)"]
    internet_access     = "Full outbound access via Internet Gateway"
  }
}

output "deployment_metadata" {
  description = "Deployment metadata and configuration summary"
  value = {
    # Tier configuration
    adb_tier_enabled       = var.use_always_free_adb
    compute_tier_enabled   = var.use_always_free_compute
    
    # Resource configuration
    resource_prefix        = var.resource_prefix
    database_name          = var.db_name
    database_workload      = var.adb_workload
    database_version       = var.adb_version
    
    # Technology stack
    python_driver          = "python-oracledb"
    connection_mode        = "Thin mode"
    security_protocol      = "mTLS"
    
    # Deployment info
    deployment_time        = timestamp()
    terraform_version      = ">=1.0"
    oci_provider_version   = ">=4.67.3"
    
    # Configuration summary
    configuration_type     = "${var.use_always_free_adb ? "Free" : "Payable"}_ADB_${var.use_always_free_compute ? "Free" : "Custom"}_Compute"
    
    # Feature flags
    features_enabled = {
      auto_scaling_cpu     = var.use_always_free_adb ? false : var.adb_auto_scaling_enabled
      auto_scaling_storage = var.use_always_free_adb ? false : var.adb_auto_scaling_for_storage_enabled
      database_management  = var.use_always_free_adb ? false : (var.adb_database_management_status == "ENABLED")
      operations_insights  = var.use_always_free_adb ? false : (var.adb_operations_insights_status == "ENABLED")
      web_access          = true
      jupyter_notebook    = true
      flask_development   = true
    }
  }
}