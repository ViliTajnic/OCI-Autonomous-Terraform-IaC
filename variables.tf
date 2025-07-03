variable "use_free_tier" {
  description = "Whether to use Always Free tier resources"
  type        = bool
  default     = true
}

variable "compartment_id" {
  description = "OCI Compartment OCID"
  type        = string
}

variable "adb_admin_password" {
  description = "Admin password for Autonomous Database (must meet complexity rules)"
  type        = string
  sensitive   = true
}

# Only used when not using free tier
variable "adb_cpu_core_count" {
  type    = number
  default = 1
}

variable "adb_data_storage_size_in_tbs" {
  type    = number
  default = 1
}

variable "compute_shape" {
  type    = string
  default = "VM.Standard.E4.Flex"
}

variable "compute_ocpus" {
  type    = number
  default = 1
}

variable "compute_memory_in_gbs" {
  type    = number
  default = 8
}

locals {
  adb_cpu_core_count          = var.use_free_tier ? 1 : var.adb_cpu_core_count
  adb_data_storage_size_in_tbs = var.use_free_tier ? 1 : var.adb_data_storage_size_in_tbs
  compute_shape               = var.use_free_tier ? "VM.Standard.A1.Flex" : var.compute_shape
  compute_ocpus               = var.use_free_tier ? 1 : var.compute_ocpus
  compute_memory_in_gbs       = var.use_free_tier ? 1 : var.compute_memory_in_gbs
}
