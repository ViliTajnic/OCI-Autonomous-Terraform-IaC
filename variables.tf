# Core Configuration
variable "compartment_id" {
  description = "The compartment OCID where resources will be created"
  type        = string
}

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

# Deployment Mode Toggle
variable "use_free_tier" {
  description = "Use Always Free tier resources (true) or paid tier (false)"
  type        = bool
  default     = true
}

# Resource Naming
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

# Compute Instance Configuration (Paid Tier Only)
variable "instance_shape" {
  description = "Instance shape for paid tier"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs for flex instance (paid tier only)"
  type        = number
  default     = 2
  validation {
    condition     = var.instance_ocpus >= 1 && var.instance_ocpus <= 64
    error_message = "Instance OCPUs must be between 1 and 64."
  }
}

variable "instance_memory_gb" {
  description = "Amount of memory in GB for flex instance (paid tier only)"
  type        = number
  default     = 16
  validation {
    condition     = var.instance_memory_gb >= 1 && var.instance_memory_gb <= 1024
    error_message = "Instance memory must be between 1 and 1024 GB."
  }
}

# Autonomous Database Configuration (Paid Tier Only)
variable "adb_cpu_core_count" {
  description = "Number of CPU cores for ADB (paid tier only)"
  type        = number
  default     = 2
  validation {
    condition     = var.adb_cpu_core_count >= 1 && var.adb_cpu_core_count <= 128
    error_message = "ADB CPU core count must be between 1 and 128."
  }
}

variable "adb_storage_tb" {
  description = "Storage size in TB for ADB (paid tier only)"
  type        = number
  default     = 1
  validation {
    condition     = var.adb_storage_tb >= 1 && var.adb_storage_tb <= 384
    error_message = "ADB storage must be between 1 and 384 TB."
  }
}

variable "adb_auto_scaling" {
  description = "Enable auto-scaling for ADB (paid tier only)"
  type        = bool
  default     = false
}

variable "adb_backup_retention_days" {
  description = "Backup retention period in days (paid tier only)"
  type        = number
  default     = 7
  validation {
    condition     = var.adb_backup_retention_days >= 1 && var.adb_backup_retention_days <= 60
    error_message = "Backup retention must be between 1 and 60 days."
  }
}

# Database Configuration
variable "adb_version" {
  description = "Autonomous Database version"
  type        = string
  default     = "19c"
}

variable "adb_license_model" {
  description = "License model for ADB"
  type        = string
  default     = "LICENSE_INCLUDED"
  validation {
    condition     = contains(["LICENSE_INCLUDED", "BRING_YOUR_OWN_LICENSE"], var.adb_license_model)
    error_message = "License model must be either LICENSE_INCLUDED or BRING_YOUR_OWN_LICENSE."
  }
}

variable "adb_workload" {
  description = "Workload type for ADB"
  type        = string
  default     = "OLTP"
  validation {
    condition     = contains(["OLTP", "DW", "AJD"], var.adb_workload)
    error_message = "Workload must be OLTP, DW, or AJD."
  }
}

# Network Configuration
variable "enable_web_ports" {
  description = "Enable HTTP (80) and HTTPS (443) ports"
  type        = bool
  default     = false
}