output "autonomous_database_id" {
  description = "OCID of the Autonomous Database"
  value       = oci_database_autonomous_database.adb.id
}

output "database_connection_info" {
  description = "Database connection information"
  value = {
    database_name      = oci_database_autonomous_database.adb.db_name
    display_name       = oci_database_autonomous_database.adb.display_name
    admin_username     = "ADMIN"
    workload_type      = "OLTP (ATP)"
    is_free_tier       = var.is_free_tier
    cpu_cores          = var.is_free_tier ? 1 : var.adb_cpu_core_count
    storage_info       = var.is_free_tier ? "20GB (Always Free)" : "${var.adb_data_storage_size_in_tbs}TB"
    connection_strings = oci_database_autonomous_database.adb.connection_strings
    service_levels     = ["high", "medium", "low", "tp", "tpurgent"]
  }
}

output "adb_service_console_url" {
  description = "URL to access the Autonomous Database service console"
  value       = coalesce(oci_database_autonomous_database.adb.service_console_url, "Console URL will be available after deployment completes")
}

output "compute_instance_public_ip" {
  description = "Public IP address of the compute instance"
  value       = oci_core_instance.python_host.public_ip
}

output "ssh_connection_command" {
  description = "Command to connect to the compute instance via SSH"
  value       = "ssh -i <private_key_file> opc@${oci_core_instance.python_host.public_ip}"
}

output "wallet_password" {
  description = "Auto-generated password for the database wallet"
  value       = random_password.wallet_password.result
  sensitive   = true
}

output "python_test_command" {
  description = "Command to test Python database connectivity on the compute instance"
  value       = "sudo su - oracle && python3 /home/oracle/test_connection.py"
}

output "deployment_summary" {
  description = "Complete deployment summary and next steps"
  value = <<-EOT
    🎉 Oracle Autonomous Database with Python Host - Deployment Complete!
    
    📊 Database Information:
    - Name: ${oci_database_autonomous_database.adb.db_name}
    - Display Name: ${oci_database_autonomous_database.adb.display_name}
    - Workload: OLTP (Autonomous Transaction Processing)
    - CPU Cores: ${var.is_free_tier ? 1 : var.adb_cpu_core_count}
    - Storage: ${var.is_free_tier ? "20GB (Always Free)" : "${var.adb_data_storage_size_in_tbs}TB"}
    - Free Tier: ${var.is_free_tier}
    
    🖥️  Compute Instance:
    - Name: ${oci_core_instance.python_host.display_name}
    - Shape: ${var.instance_shape}
    - Public IP: ${oci_core_instance.python_host.public_ip}
    
    🚀 Setup Steps:
    1. SSH to instance: ssh -i <key> opc@${oci_core_instance.python_host.public_ip}
    2. Switch to oracle user: sudo su - oracle
    
    💳 Download Wallet (Required):
    3. Go to OCI Console → Oracle Database → Autonomous Database
    4. Click "${oci_database_autonomous_database.adb.display_name}" → DB Connection
    5. Download Wallet → Save as wallet.zip
    6. Upload to instance: scp wallet.zip opc@${oci_core_instance.python_host.public_ip}:
    7. On instance: sudo cp wallet.zip /home/oracle/ && sudo chown oracle:oracle /home/oracle/wallet.zip
    8. Extract: sudo su - oracle && cd /home/oracle/wallet && unzip ../wallet.zip
    9. Test: python3 test.py
    
    🔑 Connection Details:
    - Admin Username: ADMIN
    - Admin Password: [Your configured password]
    - Wallet Password: [Use any password when downloading]
    
    🔧 Pre-configured:
    ✅ Oracle Instant Client 19.21
    ✅ Python 3 with cx_Oracle
    ✅ Environment variables set
    ✅ Test script ready
    
    Happy coding! 🎯
  EOT
}

output "wallet_download_instructions" {
  description = "Step-by-step wallet download instructions"
  value = <<-EOT
    To complete the setup, download the ADB wallet:
    
    1. Go to: ${coalesce(oci_database_autonomous_database.adb.service_console_url, "OCI Console → Oracle Database → Autonomous Database")}
    2. Click "${oci_database_autonomous_database.adb.display_name}"
    3. Click "DB Connection" button
    4. Click "Download Wallet"
    5. Set any password (remember it)
    6. Save as wallet.zip
    7. Upload to instance: scp wallet.zip opc@${oci_core_instance.python_host.public_ip}:
    8. SSH and extract: ssh opc@${oci_core_instance.python_host.public_ip}
       sudo cp wallet.zip /home/oracle/
       sudo chown oracle:oracle /home/oracle/wallet.zip
       sudo su - oracle
       cd wallet && unzip ../wallet.zip
    9. Test: python3 test.py
  EOT
}