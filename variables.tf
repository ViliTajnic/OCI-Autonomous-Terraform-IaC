# ===================================================================
# AUTOMATICALLY PROVIDED BY OCI RESOURCE MANAGER
# ===================================================================

variable "compartment_ocid" {
  description = "Compartment OCID (auto-provided by OCI Resource Manager)"
  type        = string
}

variable "tenancy_ocid" {
  description = "Tenancy OCID (auto-provided by OCI Resource Manager)"
  type        = string
  default     = ""
}

variable "region" {
  description = "Region (auto-provided by OCI Resource Manager)"
  type        = string
  default     = ""
}

# ===================================================================
# REQUIRED INPUTS
# ===================================================================

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "admin_password" {
  description = "Admin password for database and system access"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.admin_password) >= 8
    error_message = "Password must be at least 8 characters long."
  }
}

# ===================================================================
# DEPLOYMENT MODE
# ===================================================================

variable "use_free_tier" {
  description = "Use Always Free resources (true) or paid resources (false)"
  type        = bool
  default     = true
}

# ===================================================================
# BASIC CONFIGURATION
# ===================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "python-oracle"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.project_name))
    error_message = "Project name must start with a letter and contain only letters, numbers, and hyphens."
  }
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "PYTHONDB"
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9]*$", var.database_name)) && length(var.database_name) <= 14
    error_message = "Database name must start with a letter, be alphanumeric only, and max 14 characters."
  }
}

# ===================================================================
# PAID TIER CONFIGURATION (only used when use_free_tier = false)
# ===================================================================

variable "compute_ocpus" {
  description = "Number of OCPUs for compute instance (paid tier only)"
  type        = number
  default     = 2
  validation {
    condition     = var.compute_ocpus >= 1 && var.compute_ocpus <= 32
    error_message = "OCPUs must be between 1 and 32."
  }
}

variable "compute_memory_gb" {
  description = "Memory in GB for compute instance (paid tier only)"
  type        = number
  default     = 16
  validation {
    condition     = var.compute_memory_gb >= 1 && var.compute_memory_gb <= 512
    error_message = "Memory must be between 1 and 512 GB."
  }
}

variable "adb_cpu_cores" {
  description = "Number of CPU cores for Autonomous Database (paid tier only)"
  type        = number
  default     = 2
  validation {
    condition     = var.adb_cpu_cores >= 1 && var.adb_cpu_cores <= 128
    error_message = "ADB CPU cores must be between 1 and 128."
  }
}

variable "adb_storage_gb" {
  description = "Storage in GB for Autonomous Database (paid tier only)"
  type        = number
  default     = 1024
  validation {
    condition     = var.adb_storage_gb >= 20 && var.adb_storage_gb <= 393216
    error_message = "ADB storage must be between 20GB and 393,216GB."
  }
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for Autonomous Database (paid tier only)"
  type        = bool
  default     = false
}