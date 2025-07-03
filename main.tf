terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

# Get current compartment and availability domain
data "oci_identity_availability_domain" "ad" {
  compartment_id = var.compartment_ocid
  ad_number      = 1
}

data "oci_core_images" "ol8_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.use_free_tier ? "VM.Standard.E2.1.Micro" : "VM.Standard.E4.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# VCN
resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.project_name}-vcn"
  cidr_block     = "10.0.0.0/16"
  dns_label      = "pythonvcn"
}

# Internet Gateway
resource "oci_core_internet_gateway" "ig" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-ig"
}

# Route Table
resource "oci_core_route_table" "rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.ig.id
  }
}

# Security List
resource "oci_core_security_list" "sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "${var.project_name}-sl"

  # Outbound traffic
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # SSH
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Flask (5000)
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 5000
      max = 5000
    }
  }
}

# Public Subnet
resource "oci_core_subnet" "public_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.vcn.id
  display_name               = "${var.project_name}-subnet"
  cidr_block                 = "10.0.1.0/24"
  dns_label                  = "publicsubnet"
  route_table_id             = oci_core_route_table.rt.id
  security_list_ids          = [oci_core_security_list.sl.id]
  prohibit_public_ip_on_vnic = false
}

# Compute Instance
resource "oci_core_instance" "python_instance" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "${var.project_name}-instance"
  shape               = var.use_free_tier ? "VM.Standard.E2.1.Micro" : "VM.Standard.E4.Flex"

  # Only configure shape_config for paid tier
  dynamic "shape_config" {
    for_each = var.use_free_tier ? [] : [1]
    content {
      ocpus         = var.compute_ocpus
      memory_in_gbs = var.compute_memory_gb
    }
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet.id
    display_name     = "${var.project_name}-vnic"
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ol8_images.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
      admin_password = var.admin_password
    }))
  }

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.use_free_tier ? "Free" : "Paid"
    "CreatedBy"   = "Terraform"
  }
}

# Autonomous Database
resource "oci_database_autonomous_database" "adb" {
  compartment_id = var.compartment_ocid
  
  # Basic configuration
  db_name        = var.database_name
  display_name   = "${var.project_name}-adb"
  admin_password = var.admin_password
  
  # Conditional configuration based on free/paid tier
  cpu_core_count          = var.use_free_tier ? 1 : var.adb_cpu_cores
  data_storage_size_in_gb = var.use_free_tier ? 20 : var.adb_storage_gb
  is_free_tier            = var.use_free_tier
  
  # Auto-scaling only for paid tier
  is_auto_scaling_enabled = var.use_free_tier ? false : var.enable_auto_scaling
  
  # Database settings
  db_version    = "23ai"
  db_workload   = "OLTP"
  license_model = "LICENSE_INCLUDED"

  freeform_tags = {
    "Project"     = var.project_name
    "Environment" = var.use_free_tier ? "Free" : "Paid"
    "CreatedBy"   = "Terraform"
  }
}