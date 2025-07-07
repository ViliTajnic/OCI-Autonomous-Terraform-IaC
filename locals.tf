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
  
  # ALWAYS FREE COMPUTE PERFORMANCE TIERS
  
  # Define performance configurations for Always Free
  always_free_configs = {
    minimal = {
      description = "Basic demo - 1 OCPU, 6GB RAM"
      ocpus       = 1
      memory_gb   = 6
      use_case    = "Light demos, basic development"
    }
    balanced = {
      description = "Good performance - 2 OCPU, 12GB RAM" 
      ocpus       = 2
      memory_gb   = 12
      use_case    = "Most demos, Python development"
    }
    maximum = {
      description = "Full Always Free - 4 OCPU, 24GB RAM"
      ocpus       = 4
      memory_gb   = 24
      use_case    = "Heavy workloads, multiple users"
    }
  }
  
  # Get selected performance tier configuration
  selected_performance = local.always_free_configs[var.always_free_performance_tier]
  
  # SIMPLE SHAPE SELECTION - Use variable to let user choose
  # This avoids complex API queries that might fail
  
  # Default shape preferences by priority (ordered by availability)
  shape_preference_map = {
    "ampere_a1"     = "VM.Standard.A1.Flex"      # ARM Ampere A1 - BEST availability
    "intel_e3_flex" = "VM.Standard.E3.Flex"      # Intel x86 - GOOD availability  
    "intel_micro"   = "VM.Standard.E2.1.Micro"   # Intel x86 - EXCELLENT availability
    "ampere_a2"     = "VM.Standard.A2.Flex"      # ARM Ampere A2 - Variable availability
    "intel_e4_flex" = "VM.Standard.E4.Flex"      # Intel x86 - LIMITED availability
    "amd_e3_flex"   = "VM.Standard.E3.Flex"      # AMD x86 - Use E3.Flex for AMD
  }
  
  # Use variable or default to A1.Flex
  selected_shape = lookup(local.shape_preference_map, var.preferred_shape, "VM.Standard.A1.Flex")
  
  # Shape type determination
  shape_type = (
    length(regexall("A1|A2", local.selected_shape)) > 0 ? "Ampere-ARM" :
    length(regexall("E2.1.Micro", local.selected_shape)) > 0 ? "Intel-x86-Micro" :
    length(regexall("E3.Flex", local.selected_shape)) > 0 ? "Intel-x86-Flex" :
    length(regexall("E4.Flex", local.selected_shape)) > 0 ? "Intel-x86-Gen4" :
    "Standard-x86"
  )
  
  # Smart shape configuration based on selected shape and performance tier
  shape_config = (
    # Ampere A1.Flex - Use performance tier configuration
    local.selected_shape == "VM.Standard.A1.Flex" ? {
      ocpus         = local.selected_performance.ocpus
      memory_in_gbs = local.selected_performance.memory_gb
    } :
    # Ampere A2.Flex - Use performance tier configuration  
    local.selected_shape == "VM.Standard.A2.Flex" ? {
      ocpus         = local.selected_performance.ocpus
      memory_in_gbs = local.selected_performance.memory_gb
    } :
    # Intel E3.Flex - Use performance tier configuration (Always Free compatible)
    local.selected_shape == "VM.Standard.E3.Flex" ? {
      ocpus         = local.selected_performance.ocpus
      memory_in_gbs = local.selected_performance.memory_gb
    } :
    # Intel E4.Flex - Use performance tier configuration (Always Free compatible)
    local.selected_shape == "VM.Standard.E4.Flex" ? {
      ocpus         = local.selected_performance.ocpus
      memory_in_gbs = local.selected_performance.memory_gb
    } :
    # E2.1.Micro - Fixed shape, limited to 1 OCPU, 1GB (ignore performance tier)
    local.selected_shape == "VM.Standard.E2.1.Micro" ? null :
    # Other flex shapes - use balanced config
    length(regexall("Flex", local.selected_shape)) > 0 ? {
      ocpus         = local.selected_performance.ocpus
      memory_in_gbs = local.selected_performance.memory_gb
    } : null
  )
  
  # Determine best availability domain with fallback logic
  # Try all ADs in order to find capacity
  available_ads = data.oci_identity_availability_domains.ads.availability_domains
  
  # For E2.1.Micro, prefer AD-3 but fall back to others
  # For Ampere shapes, try all ADs starting with AD-1
  selected_ad_index = local.selected_shape == "VM.Standard.E2.1.Micro" ? (
    length(local.available_ads) >= 3 ? 2 : 0  # Try AD-3 first, then AD-1
  ) : 0  # For Ampere, start with AD-1
  
  selected_ad = local.available_ads[local.selected_ad_index].name
  
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