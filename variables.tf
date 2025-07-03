# ===================================================================
# AUTOMATICALLY PROVIDED BY OCI RESOURCE MANAGER
# ===================================================================

variable "compartment_ocid" {
  description = "Compartment OCID (automatically provided by OCI Resource Manager)"
  type        = string
  default     = ""
}

variable "tenancy_ocid" {
  description = "Tenancy OCID (automatically provided by OCI Resource Manager)"
  type        = string
  default     = ""
}

variable "region" {
  description = "Region (automatically provided by OCI Resource Manager)"
  type        = string
  default     = ""
}

# ===================================================================
# REQUIRED CONFIGURATION (Only 2 inputs needed!)
# ===================================================================

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "db_admin_password" {
  description = "Admin password for Autonomous Database (8+ characters, must include uppercase, lowercase, number)"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_admin_password) >= 8
    error_message = "Database admin password must be at least 8 characters long."
  }
}

# ===================================================================
# DEPLOYMENT MODE (Free vs Payable ADB)
# ===================================================================

variable "use_always_free_adb" {
  description = "Use Always Free Autonomous Database (true) or Payable ADB with custom resources (false)"
  type        = bool
  default     = true
}

# ===================================================================
# BASIC SETTINGS (Optional customization)
# ===================================================================

variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "python-oracle"
}

variable "db_name" {
  description = "Database name (alphanumeric only, max 14 chars)"
  type        = string
  default     = "PYTHONADB"
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9]*$", var.db_name)) && length(var.db_name) <= 14
    error_message = "Database name must start with a letter, contain only alphanumeric characters, and be max 14 characters."
  }
}

# ===================================================================
# PAYABLE ADB CONFIGURATION
# (Only used when use_always_free_adb = false)
# ===================================================================

variable "adb_cpu_core_count" {
  description = "Number of CPU cores for Autonomous Database (payable tier only)"
  type        = number
  default     = 2
  validation {
    condition     = var.adb_cpu_core_count >= 1 && var.adb_cpu_core_count <= 128
    error_message = "ADB CPU core count must be between 1 and 128."
  }
}

variable "adb_data_storage_size_in_gb" {
  description = "Database storage in GB for payable tier (minimum 20GB)"
  type        = number
  default     = 1024
  validation {
    condition     = var.adb_data_storage_size_in_gb >= 20 && var.adb_data_storage_size_in_gb <= 393216
    error_message = "ADB storage must be between 20GB and 393,216GB (384TB)."
  }
}

variable "adb_auto_scaling_enabled" {
  description = "Enable auto-scaling for ADB (payable tier only)"
  type        = bool
  default     = false
}

variable "adb_auto_scaling_max_cpu_core_count" {
  description = "Maximum CPU cores for auto-scaling (payable tier only)"
  type        = number
  default     = 4
  validation {
    condition     = var.adb_auto_scaling_max_cpu_core_count >= 1 && var.adb_auto_scaling_max_cpu_core_count <= 128
    error_message = "Auto-scaling max CPU cores must be between 1 and 128."
  }
}

# ===================================================================
# COMPUTE INSTANCE CONFIGURATION
# ===================================================================

variable "use_always_free_compute" {
  description = "Use Always Free compute instance (true) or custom shape (false)"
  type        = bool
  default     = true
}

variable "instance_shape" {
  description = "Instance shape for custom compute (when use_always_free_compute = false)"
  type        = string
  default     = "VM.Standard.E4.Flex"
  validation {
    condition = contains([
      "VM.Standard.E3.Flex",
      "VM.Standard.E4.Flex", 
      "VM.Standard.A1.Flex",
      "VM.Standard3.Flex"
    ], var.instance_shape)
    error_message = "Must be a valid Flex shape: VM.Standard.E3.Flex, VM.Standard.E4.Flex, VM.Standard.A1.Flex, or VM.Standard3.Flex."
  }
}

variable "instance_ocpus" {
  description = "Number of OCPUs for custom compute instance"
  type        = number
  default     = 2
  validation {
    condition     = var.instance_ocpus >= 1 && var.instance_ocpus <= 64
    error_message = "Instance OCPUs must be between 1 and 64."
  }
}

variable "instance_memory_gb" {
  description = "Memory in GB for custom compute instance"
  type        = number
  default     = 16
  validation {
    condition     = var.instance_memory_gb >= 1 && var.instance_memory_gb <= 1024
    error_message = "Instance memory must be between 1 and 1024 GB."
  }
}

# ===================================================================
# ADVANCED DATABASE OPTIONS
# ===================================================================

variable "adb_version" {
  description = "Oracle Database version (always 23ai for latest features)"
  type        = string
  default     = "23ai"
  validation {
    condition     = var.adb_version == "23ai"
    error_message = "Database version must be 23ai for optimal performance and features."
  }
}

variable "adb_workload" {
  description = "Database workload type"
  type        = string
  default     = "OLTP"
  validation {
    condition     = contains(["OLTP", "DW", "AJD"], var.adb_workload)
    error_message = "Workload must be OLTP (transactions), DW (data warehouse), or AJD (JSON)."
  }
}

variable "adb_license_model" {
  description = "Database license model"
  type        = string
  default     = "LICENSE_INCLUDED"
  validation {
    condition     = contains(["LICENSE_INCLUDED", "BRING_YOUR_OWN_LICENSE"], var.adb_license_model)
    error_message = "License model must be LICENSE_INCLUDED or BRING_YOUR_OWN_LICENSE."
  }
}

variable "adb_backup_retention_period_in_days" {
  description = "Backup retention period in days (payable tier only)"
  type        = number
  default     = 7
  validation {
    condition     = var.adb_backup_retention_period_in_days >= 1 && var.adb_backup_retention_period_in_days <= 60
    error_message = "Backup retention must be between 1 and 60 days."
  }
}

# ===================================================================
# NETWORK CONFIGURATION
# ===================================================================

variable "enable_web_access" {
  description = "Enable HTTP (80) and HTTPS (443) ports for web applications"
  type        = bool
  default     = true
}