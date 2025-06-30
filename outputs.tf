output "database_id" {
  value = oci_database_autonomous_database.adb.id
}

output "instance_ip" {
  value = oci_core_instance.instance.public_ip
}

output "ssh_command" {
  value = "ssh opc@${oci_core_instance.instance.public_ip}"
}

output "setup_instructions" {
  value = <<-EOT
    1. SSH: ssh opc@${oci_core_instance.instance.public_ip}
    2. Download wallet from OCI Console → Oracle Database → PythonADB → DB Connection
    3. Upload wallet: scp wallet.zip opc@${oci_core_instance.instance.public_ip}:
    4. Extract: unzip wallet.zip -d wallet/
    5. Test: python3 test_connect.py
    6. Happy testing!
  EOT
}