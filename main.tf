# Configure the Oracle Cloud Infrastructure Provider
terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

# Get current compartment from the execution context
# OCI Resource Manager automatically provides compartment_ocid
locals {
  # Current compartment from OCI Resource Manager context
  current_compartment_id = var.compartment_ocid
  
  # Always Free tier configurations
  free_tier_compute_shape = "VM.Standard.E2.1.Micro"
  free_tier_adb_cpu_cores = 1
  free_tier_adb_storage_gb = 20

  # Determine actual compute configuration
  actual_instance_shape = var.use_always_free_compute ? local.free_tier_compute_shape : var.instance_shape
  
  # Determine actual ADB configuration
  actual_adb_cpu_cores = var.use_always_free_adb ? local.free_tier_adb_cpu_cores : var.adb_cpu_core_count
  actual_adb_storage_gb = var.use_always_free_adb ? local.free_tier_adb_storage_gb : var.adb_data_storage_size_in_gb
  
  # Auto-scaling only available for payable tier
  adb_auto_scaling_enabled = var.use_always_free_adb ? false : var.adb_auto_scaling_enabled
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = local.current_compartment_id
  ad_number      = 1
}

data "oci_core_images" "compute_images" {
  compartment_id           = local.current_compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = local.actual_instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# VCN
resource "oci_core_vcn" "vcn" {
  compartment_id = local.current_compartment_id
  display_name   = "${var.resource_prefix}-vcn"
  cidr_block     = "10.0.0.0/16"
  dns_label      = "pythonvcn"

  freeform_tags = {
    "Environment" = var.use_always_free_adb ? "Development" : "Production"
    "ADB_Tier"    = var.use_always_free_adb ? "Always-Free" : "Payable"
    "Compute_Tier" = var.use_always_free_compute ? "Always-Free" : "Custom"
  }
}

# Internet Gateway
resource "oci_core_internet_gateway" "ig" {
  compartment_id = local.current_compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.resource_prefix}-ig"
}

# Route table
resource "oci_core_route_table" "public_rt" {
  compartment_id = local.current_compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.resource_prefix}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.ig.id
  }
}

# Security list
resource "oci_core_security_list" "public_sl" {
  compartment_id = local.current_compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.resource_prefix}-public-sl"

  # Outbound traffic
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # SSH access
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP access (always enabled for web development)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS access (always enabled for web development)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Flask development port (always enabled)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 5000
      max = 5000
    }
  }

  # Jupyter notebook port (always enabled)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 8888
      max = 8888
    }
  }
}

# Public subnet
resource "oci_core_subnet" "public_subnet" {
  compartment_id             = local.current_compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  display_name               = "${var.resource_prefix}-public-subnet"
  cidr_block                 = "10.0.1.0/24"
  dns_label                  = "publicsubnet"
  route_table_id             = oci_core_route_table.public_rt.id
  security_list_ids          = [oci_core_security_list.public_sl.id]
  prohibit_public_ip_on_vnic = false
}

# Compute instance
resource "oci_core_instance" "compute_instance" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = local.current_compartment_id
  display_name        = "${var.resource_prefix}-instance"
  shape               = local.actual_instance_shape

  # Shape configuration (only for custom compute instances)
  dynamic "shape_config" {
    for_each = var.use_always_free_compute ? [] : [1]
    content {
      ocpus         = var.instance_ocpus
      memory_in_gbs = var.instance_memory_gb
    }
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet.id
    display_name     = "${var.resource_prefix}-vnic"
    assign_public_ip = true
    hostname_label   = "pythonhost"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.compute_images.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
      db_password = var.db_admin_password
    }))
  }

  freeform_tags = {
    "Environment" = var.use_always_free_adb ? "Development" : "Production"
    "ADB_Tier"    = var.use_always_free_adb ? "Always-Free" : "Payable"
    "Compute_Tier" = var.use_always_free_compute ? "Always-Free" : "Custom"
    "Shape"       = local.actual_instance_shape
  }
}

# Autonomous Database
resource "oci_database_autonomous_database" "adb" {
  compartment_id = local.current_compartment_id
  
  # Core configuration
  cpu_core_count = local.actual_adb_cpu_cores
  
  # Storage configuration
  data_storage_size_in_gb = local.actual_adb_storage_gb
  
  db_name        = var.db_name
  admin_password = var.db_admin_password
  display_name   = "${var.resource_prefix}-adb"
  
  # Database settings - Always use 23ai for latest features
  db_version    = var.adb_version
  db_workload   = var.adb_workload
  license_model = var.adb_license_model
  
  # Free tier setting
  is_free_tier = var.use_always_free_adb
  
  # Auto-scaling configuration (payable tier only)
  is_auto_scaling_enabled = local.adb_auto_scaling_enabled
  
  # Enhanced security and networking
  subnet_id                = oci_core_subnet.public_subnet.id
  whitelisted_ips          = ["0.0.0.0/0"]
  are_primary_whitelisted_ips_used = true
  
  # Additional configuration
  is_dedicated = false

  freeform_tags = {
    "Environment" = var.use_always_free_adb ? "Development" : "Production"
    "ADB_Tier"    = var.use_always_free_adb ? "Always-Free" : "Payable"
    "Compute_Tier" = var.use_always_free_compute ? "Always-Free" : "Custom"
    "Workload"    = var.adb_workload
    "Version"     = var.adb_version
    "CreatedBy"   = "Terraform"
    "CPU_Cores"   = tostring(local.actual_adb_cpu_cores)
    "Storage_GB"  = tostring(local.actual_adb_storage_gb)
    "Auto_Scaling" = var.use_always_free_adb ? "Not_Available" : (var.adb_auto_scaling_enabled ? "Enabled" : "Disabled")
  }
  
  # Lifecycle management
  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}