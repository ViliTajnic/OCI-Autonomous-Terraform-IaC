# Configure the Oracle Cloud Infrastructure Provider
terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

# Data sources for availability domain and compute images
data "oci_identity_availability_domain" "ad" {
  compartment_id = var.compartment_id
  ad_number      = 1
}

data "oci_core_images" "compute_images" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.use_free_tier ? "VM.Standard.E2.1.Micro" : var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# VCN
resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_id
  display_name   = "${var.resource_prefix}-vcn"
  cidr_block     = "10.0.0.0/16"
  dns_label      = "pythonvcn"
}

# Internet Gateway
resource "oci_core_internet_gateway" "ig" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.resource_prefix}-ig"
}

# Route table for public subnet
resource "oci_core_route_table" "public_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.resource_prefix}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.ig.id
  }
}

# Security list for public subnet
resource "oci_core_security_list" "public_sl" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.resource_prefix}-public-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  dynamic "ingress_security_rules" {
    for_each = var.enable_web_ports ? [1] : []
    content {
      protocol = "6" # TCP
      source   = "0.0.0.0/0"
      tcp_options {
        min = 80
        max = 80
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = var.enable_web_ports ? [1] : []
    content {
      protocol = "6" # TCP
      source   = "0.0.0.0/0"
      tcp_options {
        min = 443
        max = 443
      }
    }
  }
}

# Public subnet
resource "oci_core_subnet" "public_subnet" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.vcn.id
  display_name        = "${var.resource_prefix}-public-subnet"
  cidr_block          = "10.0.1.0/24"
  dns_label           = "publicsubnet"
  route_table_id      = oci_core_route_table.public_rt.id
  security_list_ids   = [oci_core_security_list.public_sl.id]
  prohibit_public_ip_on_vnic = false
}

# Compute instance
resource "oci_core_instance" "compute_instance" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_id
  display_name        = "${var.resource_prefix}-instance"
  shape               = var.use_free_tier ? "VM.Standard.E2.1.Micro" : var.instance_shape

  dynamic "shape_config" {
    for_each = var.use_free_tier ? [] : [1]
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
}

# Autonomous Database
resource "oci_database_autonomous_database" "adb" {
  compartment_id           = var.compartment_id
  cpu_core_count           = var.use_free_tier ? 1 : var.adb_cpu_core_count
  data_storage_size_in_tbs = var.use_free_tier ? null : var.adb_storage_tb
  data_storage_size_in_gbs = var.use_free_tier ? 20 : null
  db_name                  = var.db_name
  admin_password           = var.db_admin_password
  db_version               = var.adb_version
  display_name             = "${var.resource_prefix}-adb"
  license_model            = var.adb_license_model
  is_free_tier             = var.use_free_tier
  db_workload              = var.adb_workload
  
  # Auto-scaling (only for paid tier)
  is_auto_scaling_enabled = var.use_free_tier ? false : var.adb_auto_scaling
  
  # Backup retention (only for paid tier)
  backup_retention_period_in_days = var.use_free_tier ? null : var.adb_backup_retention_days
}