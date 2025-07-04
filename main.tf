terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

# Get latest Oracle Linux image for Always Free shape
data "oci_core_images" "oracle_linux" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = local.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Create VCN
resource "oci_core_vcn" "python_vcn" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [local.vcn_cidr]
  display_name   = local.vcn_name
  dns_label      = "pythonadb"

  freeform_tags = local.common_tags
}

# Create Internet Gateway
resource "oci_core_internet_gateway" "python_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.python_vcn.id
  display_name   = "${local.resource_prefix}-igw"
  enabled        = true

  freeform_tags = local.common_tags
}

# Create Route Table
resource "oci_core_route_table" "python_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.python_vcn.id
  display_name   = "${local.resource_prefix}-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.python_igw.id
  }

  freeform_tags = local.common_tags
}

# Create Security List
resource "oci_core_security_list" "python_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.python_vcn.id
  display_name   = "${local.resource_prefix}-sl"

  # Allow SSH inbound
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      max = 22
      min = 22
    }
  }

  # Allow all outbound
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  freeform_tags = local.common_tags
}

# Create Public Subnet
resource "oci_core_subnet" "python_subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.python_vcn.id
  cidr_block        = local.subnet_cidr
  display_name      = local.subnet_name
  dns_label         = "pythonsubnet"
  route_table_id    = oci_core_route_table.python_rt.id
  security_list_ids = [oci_core_security_list.python_sl.id]

  prohibit_public_ip_on_vnic = false

  freeform_tags = local.common_tags
}

# Create Autonomous Database (Always Free)
resource "oci_database_autonomous_database" "python_adb" {
  compartment_id           = var.compartment_ocid
  cpu_core_count           = 1
  data_storage_size_in_tbs = 1
  db_name                  = local.adb_db_name
  admin_password           = var.adb_admin_password
  db_workload              = "OLTP"
  display_name             = local.adb_display_name
  is_free_tier             = true
  is_auto_scaling_enabled  = false
  license_model            = "LICENSE_INCLUDED"

  freeform_tags = local.common_tags
}

# Create Compute Instance
resource "oci_core_instance" "python_instance" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  shape               = local.instance_shape
  display_name        = local.instance_name

  create_vnic_details {
    subnet_id        = oci_core_subnet.python_subnet.id
    assign_public_ip = true
    hostname_label   = "pythonhost"
  }

  source_details {
    source_id   = data.oci_core_images.oracle_linux.images[0].id
    source_type = "image"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
      adb_service_name = "${lower(local.adb_db_name)}_high"
    }))
  }

  freeform_tags = local.common_tags
}