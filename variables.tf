# ===================================================================
# REQUIRED CONFIGURATION (Always needed)
# ===================================================================

variable "tenancy_ocid" {
  description = "The tenancy OCID (automatically provided in OCI Resource Manager)"
  type        = string
  default     = ""
}

variable "compartment_id" {
  description = "The compartment OCID where resources will be created (use current compartment)"
  type        = string
  default     = ""
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

# ===================================================================
# DEPLOYMENT MODE (Default: Always Free)
# ===================================================================

variable "enable_free_tier" {
  description = "Use Always Free tier resources (recommended for development)"
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

variable "enable_web_access" {
  description = "Enable HTTP (80) and HTTPS (443) ports for web applications (always enabled)"
  type        = bool
  default     = true
}

# ===================================================================
# PAID TIER CONFIGURATION
# (Only used when enable_free_tier = false)
# ===================================================================

variable "compute_shape" {
  description = "Compute instance shape (only for paid tier)"
  type        = string
  default     = "VM.Standard.E4.Flex"
  validation {
    condition = contains([
      "VM.Standard.E3.Flex",
      "VM.Standard.E4.Flex", 
      "VM.Standard.A1.Flex",
      "VM.Standard3.Flex"
    ], var.compute_shape)
    error_message = "Must be a valid Flex shape."
  }
}

variable "compute_ocpus" {
  description = "Number of OCPUs for compute instance (only for paid tier)"
  type        = number
  default     = 2
  validation {
    condition     = var.compute_ocpus >= 1 && var.compute_ocpus <= 64
    error_message = "OCPUs must be between 1 and 64."
  }
}

variable "compute_memory_gb" {
  description = "Memory in GB for compute instance (only for paid tier)"
  type        = number
  default     = 16
  validation {
    condition     = var.compute_memory_gb >= 1 && var.compute_memory_gb <= 1024
    error_message = "Memory must be between 1 and 1024 GB."
  }
}

variable "database_ocpus" {
  description = "Number of OCPUs for Autonomous Database (only for paid tier)"
  type        = number
  default     = 2
  validation {
    condition     = var.database_ocpus >= 1 && var.database_ocpus <= 128
    error_message = "Database OCPUs must be between 1 and 128."
  }
}

variable "database_storage_tb" {
  description = "Database storage in TB (only for paid tier)"
  type        = number
  default     = 1
  validation {
    condition     = var.database_storage_tb >= 1 && var.database_storage_tb <= 384
    error_message = "Database storage must be between 1 and 384 TB."
  }
}

variable "enable_auto_scaling" {
  description = "Enable database auto-scaling (only for paid tier)"
  type        = bool
  default     = false
}

# ===================================================================
# ADVANCED OPTIONS (Rarely changed)
# ===================================================================

variable "database_version" {
  description = "Oracle Database version (fixed to 23ai)"
  type        = string
  default     = "23ai"
  validation {
    condition     = var.database_version == "23ai"
    error_message = "Database version must be 23ai."
  }
}

variable "database_workload" {
  description = "Database workload type"
  type        = string
  default     = "OLTP"
  validation {
    condition     = contains(["OLTP", "DW", "AJD"], var.database_workload)
    error_message = "Workload must be OLTP (transactions), DW (data warehouse), or AJD (JSON)."
  }
}

variable "license_model" {
  description = "Database license model"
  type        = string
  default     = "LICENSE_INCLUDED"
  validation {
    condition     = contains(["LICENSE_INCLUDED", "BRING_YOUR_OWN_LICENSE"], var.license_model)
    error_message = "License model must be LICENSE_INCLUDED or BRING_YOUR_OWN_LICENSE."
  }
}