terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

# Get availability domain
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Get Oracle Linux image
data "oci_core_images" "ol_images" {
  compartment_id   = var.compartment_ocid
  operating_system = "Oracle Linux"
  shape            = var.instance_shape
  sort_by          = "TIMECREATED"
  sort_order       = "DESC"
}

# VCN
resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = "10.0.0.0/16"
  display_name   = "adb-vcn"
}

# Internet Gateway
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "adb-igw"
}

# Route Table
resource "oci_core_route_table" "rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "adb-rt"
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

# Security List
resource "oci_core_security_list" "sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "adb-sl"
  
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
  
  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"
    tcp_options {
      min = 22
      max = 22
    }
  }
}

# Subnet
resource "oci_core_subnet" "subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.vcn.id
  cidr_block        = "10.0.1.0/24"
  display_name      = "adb-subnet"
  route_table_id    = oci_core_route_table.rt.id
  security_list_ids = [oci_core_security_list.sl.id]
}

# Autonomous Database
resource "oci_database_autonomous_database" "adb" {
  compartment_id           = var.compartment_ocid
  db_name                  = "PYTHONADB"
  display_name             = "PythonADB"
  admin_password           = var.admin_password
  cpu_core_count           = 1
  data_storage_size_in_gb  = 20
  db_workload              = "OLTP"
  is_free_tier             = true
  license_model            = "LICENSE_INCLUDED"
  whitelisted_ips          = ["0.0.0.0/0"]
}

# Compute Instance
resource "oci_core_instance" "instance" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "python-host"
  shape               = var.instance_shape

  create_vnic_details {
    subnet_id        = oci_core_subnet.subnet.id
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ol_images.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(<<-EOF
      #!/bin/bash
      yum update -y
      yum install -y python3 python3-pip wget unzip
      pip3 install cx_Oracle
      
      # Install Oracle client
      mkdir -p /opt/oracle && cd /opt/oracle
      wget -q https://download.oracle.com/otn_software/linux/instantclient/1921000/instantclient-basic-linux.x64-19.21.0.0.0dbru.zip
      unzip -q instantclient-basic-linux.x64-19.21.0.0.0dbru.zip
      
      # Set environment
      echo 'export LD_LIBRARY_PATH=/opt/oracle/instantclient_19_21:$LD_LIBRARY_PATH' >> /etc/environment
      
      # Create test script
      cat > /home/opc/test.py << 'PYEOF'
import cx_Oracle
cx_Oracle.init_oracle_client(lib_dir="/opt/oracle/instantclient_19_21")
print("Oracle client ready. Download wallet from OCI Console to /home/opc/wallet/")
print("Test connection: python3 test_connect.py")
PYEOF

      cat > /home/opc/test_connect.py << 'PYEOF'
import cx_Oracle
try:
    cx_Oracle.init_oracle_client(lib_dir="/opt/oracle/instantclient_19_21")
    connection = cx_Oracle.connect("ADMIN", "${var.admin_password}", "pythonadb_high", config_dir="/home/opc/wallet")
    cursor = connection.cursor()
    cursor.execute("SELECT 'Hello Oracle!' FROM dual")
    print("✅ Success:", cursor.fetchone()[0])
    cursor.close()
    connection.close()
except Exception as e:
    print("❌ Error:", e)
    print("Make sure wallet is in /home/opc/wallet/")
PYEOF
      
      chown opc:opc /home/opc/*.py
      mkdir -p /home/opc/wallet
      chown opc:opc /home/opc/wallet
    EOF
    )
  }
}