variable "compartment_ocid" {
  description = "OCID of the compartment where resources will be created"
  type        = string
}

variable "adb_admin_password" {
  description = "Admin password for Autonomous Database (8+ characters, must include upper/lower case, number and special character)"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for accessing the compute instance"
  type        = string
}

# Optional variables with defaults
variable "environment_tag" {
  description = "Environment tag for resources"
  type        = string
  default     = "Demo"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "Python-ADB"
}

# ADB Configuration Toggle
variable "use_free_tier" {
  description = "Use Always Free tier for Autonomous Database (set to false for paid tier)"
  type        = bool
  default     = false
}

variable "adb_cpu_core_count" {
  description = "Number of CPU cores for ADB (ignored for free tier)"
  type        = number
  default     = 1
}

variable "adb_storage_size_tbs" {
  description = "Storage size in TBs for ADB (ignored for free tier)"
  type        = number
  default     = 1
}

variable "adb_auto_scaling_enabled" {
  description = "Enable auto scaling for ADB (not available for free tier)"
  type        = bool
  default     = false
}

# Compute Shape Selection
variable "preferred_shape" {
  description = "Preferred compute shape type"
  type        = string
  default     = "ampere_a1"
  
  validation {
    condition     = contains(["ampere_a1", "ampere_a2", "intel_micro"], var.preferred_shape)
    error_message = "Preferred shape must be one of: ampere_a1, ampere_a2, intel_micro."
  }
}

# Always Free Compute Performance Options
variable "always_free_performance_tier" {
  description = "Always Free compute performance level"
  type        = string
  default     = "balanced"
  
  validation {
    condition     = contains(["minimal", "balanced", "maximum"], var.always_free_performance_tier)
    error_message = "Performance tier must be one of: minimal, balanced, maximum."
  }
}