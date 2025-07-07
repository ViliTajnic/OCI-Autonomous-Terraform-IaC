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
  
  # Database configuration with tier logic
  adb_db_name      = "PYTHONADB"
  adb_display_name = var.use_free_tier ? "PythonADB-Free" : "PythonADB-Paid"
  
  # ADB configuration based on tier
  adb_cpu_cores = var.use_free_tier ? 1 : var.adb_cpu_core_count
  adb_storage   = var.use_free_tier ? 1 : var.adb_storage_size_tbs
  adb_license   = var.use_free_tier ? "LICENSE_INCLUDED" : "LICENSE_INCLUDED"
  
  # Compute configuration (Ampere ARM-based)
  instance_shape = "VM.Standard.A2.Flex"  # Ampere ARM processor
  instance_name  = "${local.resource_prefix}-instance"
  
  # Common tags for all resources
  common_tags = {
    Environment = var.environment_tag
    Project     = var.project_name
    CreatedBy   = "Terraform-ORM"
    Purpose     = "Demo"
    Tier        = var.use_free_tier ? "Free" : "Paid"
  }
}