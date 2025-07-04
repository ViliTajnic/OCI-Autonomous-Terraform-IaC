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