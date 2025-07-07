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
  
  # SMART SHAPE DETECTION - Works for any region/user
  
  # Define Always Free eligible shapes in order of preference
  always_free_shapes = [
    "VM.Standard.A1.Flex",      # Ampere A1 (preferred - up to 4 OCPU, 24GB)
    "VM.Standard.E2.1.Micro",   # Intel micro (1 OCPU, 1GB) 
    "VM.Standard.A2.Flex"       # Ampere A2 (if available)
  ]
  
  # Get available shapes from data source
  available_shape_names = [for shape in data.oci_core_shapes.available_shapes.shapes : shape.shape]
  
  # Find the first available Always Free shape
  selected_shape = length([
    for shape in local.always_free_shapes : shape 
    if contains(local.available_shape_names, shape)
  ]) > 0 ? [
    for shape in local.always_free_shapes : shape 
    if contains(local.available_shape_names, shape)
  ][0] : null
  
  # Get details of selected shape
  selected_shape_details = local.selected_shape != null ? [
    for shape in data.oci_core_shapes.available_shapes.shapes : shape 
    if shape.shape == local.selected_shape
  ][0] : null
  
  # Determine shape type and configuration
  shape_type = local.selected_shape != null ? (
    length(regexall("A1|A2", local.selected_shape)) > 0 ? "Ampere" :
    length(regexall("E2.1.Micro", local.selected_shape)) > 0 ? "Micro" :
    "Standard"
  ) : "None"
  
  # Smart shape configuration based on detected shape
  shape_config = local.selected_shape != null ? (
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
      memory_in_gbs = 1
    } : null
  ) : null
  
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