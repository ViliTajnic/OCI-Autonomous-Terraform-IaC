# Configure the Oracle Cloud Infrastructure Provider
terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

# Data sources
data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_compartment" "current" {
  id = var.compartment_id
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.compartment_id
  ad_number      = 1
}

data "oci_core_images" "compute_images" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = local.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Local values for conditional logic
locals {
  # Always Free tier configurations
  free_tier_compute_shape = "VM.Standard.E2.1.Micro"
  free_tier_db_ocpus      = 1

  # Determine actual values based on free tier setting
  instance_shape = var.enable_free_tier ? local.free_tier_compute_shape : var.compute_shape
  database_ocpus = var.enable_free_tier ? local.free_tier_db_ocpus : var.database_ocpus
  
  # Auto-scaling only available for paid tier
  auto_scaling_enabled = var.enable_free_tier ? false : var.enable_auto_scaling
}

# VCN
resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_id
  display_name   = "${var.resource_prefix}-vcn"
  cidr_block     = "10.0.0.0/16"
  dns_label      = "pythonvcn"

  freeform_tags = {
    "Environment" = var.enable_free_tier ? "Development" : "Production"
    "Tier"        = var.enable_free_tier ? "Always-Free" : "Paid"
  }
}

# Internet Gateway
resource "oci_core_internet_gateway" "ig" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.resource_prefix}-ig"
}

# Route table
resource "oci_core_route_table" "public_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.resource_prefix}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.ig.id
  }
}

# Security list
resource "oci_core_security_list" "public_sl" {
  compartment_id = var.compartment_id
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

  # HTTP access (always enabled)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS access (always enabled)
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Flask development port
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 5000
      max = 5000
    }
  }

  # Jupyter notebook port
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
  compartment_id             = var.compartment_id
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
  compartment_id      = var.compartment_id
  display_name        = "${var.resource_prefix}-instance"
  shape               = local.instance_shape

  # Shape configuration (only for paid tier Flex shapes)
  dynamic "shape_config" {
    for_each = var.enable_free_tier ? [] : [1]
    content {
      ocpus         = var.compute_ocpus
      memory_in_gbs = var.compute_memory_gb
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
    "Environment" = var.enable_free_tier ? "Development" : "Production"
    "Tier"        = var.enable_free_tier ? "Always-Free" : "Paid"
    "Shape"       = local.instance_shape
  }
}

# Autonomous Database
resource "oci_database_autonomous_database" "adb" {
  compartment_id = var.compartment_id
  
  # Core configuration
  cpu_core_count = local.database_ocpus
  
  # Storage configuration - use different attributes based on tier
  data_storage_size_in_gb = var.enable_free_tier ? 20 : null
  data_storage_size_in_tbs = var.enable_free_tier ? null : var.database_storage_tb
  
  db_name        = var.db_name
  admin_password = var.db_admin_password
  display_name   = "${var.resource_prefix}-adb"
  
  # Database settings - Force 23ai version
  db_version    = "23ai"
  db_workload   = var.database_workload
  license_model = var.license_model
  
  # Free tier setting
  is_free_tier = var.enable_free_tier
  
  # Paid tier features (disabled for free tier)
  is_auto_scaling_enabled = local.auto_scaling_enabled
  
  # Enhanced security and networking
  subnet_id                = oci_core_subnet.public_subnet.id
  nsg_ids                  = []
  whitelisted_ips          = ["0.0.0.0/0"]
  are_primary_whitelisted_ips_used = true
  
  # Additional configuration for stability
  is_dedicated = false
  
  # Backup configuration (paid tier only)
  dynamic "backup_config" {
    for_each = var.enable_free_tier ? [] : [1]
    content {
      manual_backup_bucket_name = null
      manual_backup_type       = "NONE"
    }
  }

  freeform_tags = {
    "Environment" = var.enable_free_tier ? "Development" : "Production"
    "Tier"        = var.enable_free_tier ? "Always-Free" : "Paid"
    "Workload"    = var.database_workload
    "Version"     = "23ai"
    "CreatedBy"   = "Terraform"
  }
  
  # Lifecycle management
  lifecycle {
    ignore_changes = [
      # Ignore changes to these attributes to prevent drift
      defined_tags,
      system_tags
    ]
  }
}