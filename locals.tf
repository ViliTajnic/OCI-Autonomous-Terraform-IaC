locals {
  # Core identifiers - FIXES THE ERROR
  current_compartment_id = var.compartment_ocid
  
  # Resource naming
  resource_prefix = "python-adb"
  
  # Network configuration
  vcn_cidr    = "10.0.0.0/16"
  subnet_cidr = "10.0.1.0/24"
  vcn_name    = "${local.resource_prefix}-vcn"
  subnet_name = "${local.resource_prefix}-subnet"
  
  # Database configuration
  adb_db_name      = "PYTHONADB"
  adb_display_name = "PythonADB"
  
  # Compute configuration
  instance_shape = "VM.Standard.E2.1.Micro"
  instance_name  = "${local.resource_prefix}-instance"
  
  # Common tags for all resources
  common_tags = {
    Environment = var.environment_tag
    Project     = var.project_name
    CreatedBy   = "Terraform-ORM"
    Purpose     = "Demo"
  }
}