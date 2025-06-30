terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
  required_version = ">= 1.0"
}

# Generate random password for wallet
resource "random_password" "wallet_password" {
  length  = 16
  special = true
}

# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Get latest Oracle Linux image
data "oci_core_images" "oracle_linux_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# VCN
resource "oci_core_vcn" "adb_vcn" {
  cidr_block     = var.vcn_cidr_block
  compartment_id = var.compartment_ocid
  display_name   = "${var.adb_display_name}-vcn"
  dns_label      = "adbvcn"

  freeform_tags = {
    "CreatedBy" = "ORM-Terraform"
    "Purpose"   = "ADB-Python-Demo"
  }
}

# Internet Gateway
resource "oci_core_internet_gateway" "adb_igw" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.adb_display_name}-igw"
  vcn_id         = oci_core_vcn.adb_vcn.id
  enabled        = true

  freeform_tags = {
    "CreatedBy" = "ORM-Terraform"
    "Purpose"   = "ADB-Python-Demo"
  }
}

# Route Table
resource "oci_core_route_table" "public_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.adb_vcn.id
  display_name   = "${var.adb_display_name}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.adb_igw.id
  }

  freeform_tags = {
    "CreatedBy" = "ORM-Terraform"
    "Purpose"   = "ADB-Python-Demo"
  }
}

# Security List
resource "oci_core_security_list" "public_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.adb_vcn.id
  display_name   = "${var.adb_display_name}-public-sl"

  # Egress Rules - Allow all outbound
  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  # Ingress Rules - SSH
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ingress Rules - HTTP
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # Ingress Rules - HTTPS
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options {
      min = 443
      max = 443
    }
  }

  freeform_tags = {
    "CreatedBy" = "ORM-Terraform"
    "Purpose"   = "ADB-Python-Demo"
  }
}

# Public Subnet
resource "oci_core_subnet" "public_subnet" {
  cidr_block        = var.public_subnet_cidr_block
  display_name      = "${var.adb_display_name}-public-subnet"
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.adb_vcn.id
  route_table_id    = oci_core_route_table.public_route_table.id
  security_list_ids = [oci_core_security_list.public_security_list.id]
  dns_label         = "publicsubnet"

  freeform_tags = {
    "CreatedBy" = "ORM-Terraform"
    "Purpose"   = "ADB-Python-Demo"
  }
}

# Autonomous Database
resource "oci_database_autonomous_database" "adb" {
  compartment_id = var.compartment_ocid
  db_name        = upper(replace(var.adb_display_name, "-", ""))
  display_name   = var.adb_display_name
  admin_password = var.adb_admin_password
  cpu_core_count = var.is_free_tier ? 1 : var.adb_cpu_core_count

  # Storage configuration - use GB for free tier, TB for paid tier
  data_storage_size_in_tbs = var.is_free_tier ? null : var.adb_data_storage_size_in_tbs
  data_storage_size_in_gb  = var.is_free_tier ? 20 : null

  # Database type - ATP (Autonomous Transaction Processing)
  db_workload = "OLTP"

  # Auto scaling - Disabled for free tier, enabled for paid tier
  is_auto_scaling_enabled             = var.is_free_tier ? false : var.enable_auto_scaling
  is_auto_scaling_for_storage_enabled = var.is_free_tier ? false : var.enable_auto_scaling

  # Free tier
  is_free_tier = var.is_free_tier

  # License model
  license_model = "LICENSE_INCLUDED"

  # Minimal network configuration
  whitelisted_ips = ["0.0.0.0/0"]

  # Simplified tags
  freeform_tags = {
    "Purpose" = "Demo"
  }

  lifecycle {
    ignore_changes = [defined_tags]
  }
}

# Download ADB Wallet
resource "oci_database_autonomous_database_wallet" "adb_wallet" {
  autonomous_database_id = oci_database_autonomous_database.adb.id
  password               = random_password.wallet_password.result
  base64_encode_content  = true
}

# Compute Instance
resource "oci_core_instance" "python_host" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  display_name        = var.instance_display_name
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id                 = oci_core_subnet.public_subnet.id
    display_name              = "primary-vnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "pythonhost"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux_images.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/cloud-init.yml", {
      wallet_content     = oci_database_autonomous_database_wallet.adb_wallet.content
      wallet_password    = random_password.wallet_password.result
      adb_service_name   = "${upper(replace(var.adb_display_name, "-", ""))}_high"
      admin_password     = var.adb_admin_password
    }))
  }

  freeform_tags = {
    "CreatedBy" = "ORM-Terraform"
    "Purpose"   = "ADB-Python-Demo"
  }

  lifecycle {
    ignore_changes = [defined_tags]
  }
}