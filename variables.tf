# OCI Provider Configuration (automatically populated by ORM)
variable "tenancy_ocid" {
  description = "OCID of the tenancy"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
}

variable "compartment_ocid" {
  description = "OCID of the compartment where resources will be created"
  type        = string
}

# Autonomous Database Configuration
variable "adb_display_name" {
  description = "Display name for the Autonomous Database"
  type        = string
  default     = "PythonADB"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]*$", var.adb_display_name))
    error_message = "ADB display name must start with a letter and contain only letters, numbers, underscores, and hyphens."
  }
}

variable "adb_admin_password" {
  description = "Admin password for the Autonomous Database"
  type        = string
  sensitive   = true

  validation {
    condition = can(regex("^[A-Za-z\\d#_@!]{8,30}$", var.adb_admin_password))
    error_message = "Password must be 8-30 characters using letters, numbers, and special characters (#, _, @, !)."
  }
}

variable "adb_cpu_core_count" {
  description = "Number of CPU cores for the Autonomous Database"
  type        = number
  default     = 1

  validation {
    condition     = var.adb_cpu_core_count >= 1 && var.adb_cpu_core_count <= 128
    error_message = "CPU core count must be between 1 and 128."
  }
}

variable "adb_data_storage_size_in_tbs" {
  description = "Data storage size in terabytes"
  type        = number
  default     = 1

  validation {
    condition     = var.adb_data_storage_size_in_tbs >= 1 && var.adb_data_storage_size_in_tbs <= 384
    error_message = "Data storage size must be between 1 and 384 TB."
  }
}

variable "is_free_tier" {
  description = "Deploy using Oracle Cloud Always Free tier"
  type        = bool
  default     = false
}

variable "enable_auto_scaling" {
  description = "Enable automatic scaling for CPU and storage"
  type        = bool
  default     = true
}

# Compute Instance Configuration
variable "instance_display_name" {
  description = "Display name for the compute instance"
  type        = string
  default     = "PythonHost"
}

variable "instance_shape" {
  description = "Shape for the compute instance"
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}

variable "ssh_public_key" {
  description = "SSH public key for accessing the compute instance"
  type        = string
}

# Network Configuration
variable "vcn_cidr_block" {
  description = "CIDR block for the Virtual Cloud Network"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vcn_cidr_block, 0))
    error_message = "VCN CIDR block must be a valid CIDR notation."
  }
}

variable "public_subnet_cidr_block" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr_block, 0))
    error_message = "Public subnet CIDR block must be a valid CIDR notation."
  }
}