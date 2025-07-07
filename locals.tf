locals {
  # Core identifiers
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
  adb_license   = "LICENSE_INCLUDED"
  
  # SIMPLE SHAPE SELECTION - Use variable to let user choose
  # This avoids complex API queries that might fail
  
  # Default shape preferences by priority
  shape_preference_map = {
    "ampere_a1" = "VM.Standard.A1.Flex"
    "ampere_a2" = "VM.Standard.A2.Flex"  
    "intel_micro" = "VM.Standard.E2.1.Micro"
  }
  
  # Use variable or default to A1.Flex
  selected_shape = lookup(local.shape_preference_map, var.preferred_shape, "VM.Standard.A1.Flex")
  
  # Shape type determination
  shape_type = (
    length(regexall("A1|A2", local.selected_shape)) > 0 ? "Ampere" :
    length(regexall("E2.1.Micro", local.selected_shape)) > 0 ? "Micro" :
    "Standard"
  )
  
  # Smart shape configuration based on selected shape
  shape_config = (
    # Ampere A1.Flex - Always Free: 1-4 OCPU, up to 6GB per OCPU
    local.selected_shape == "VM.Standard.A1.Flex" ? {
      ocpus         = 1
      memory_in_gbs = 6
    } :
    # Ampere A2.Flex - Configuration varies by region
    local.selected_shape == "VM.Standard.A2.Flex" ? {
      ocpus         = 1
      memory_in_gbs = 6
    } :
    # E2.1.Micro - Fixed shape, no config needed
    local.selected_shape == "VM.Standard.E2.1.Micro" ? null :
    # Other flex shapes - conservative config
    length(regexall("Flex", local.selected_shape)) > 0 ? {
      ocpus         = 1
      memory_in_gbs = 6
    } : null
  )
  
  # Determine best availability domain
  # For E2.1.Micro, try to use AD-3 if available (common restriction)
  # For others, use first available AD
  selected_ad = local.selected_shape == "VM.Standard.E2.1.Micro" ? (
    length(data.oci_identity_availability_domains.ads.availability_domains) >= 3 ?
    data.oci_identity_availability_domains.ads.availability_domains[2].name :
    data.oci_identity_availability_domains.ads.availability_domains[0].name
  ) : data.oci_identity_availability_domains.ads.availability_domains[0].name
  
  # Instance naming
  instance_name = "${local.resource_prefix}-instance"
  
  # Common tags for all resources
  common_tags = {
    Environment = var.environment_tag
    Project     = var.project_name
    CreatedBy   = "Terraform-ORM"
    Purpose     = "Demo"
    Tier        = var.use_free_tier ? "Free" : "Paid"
  }
}