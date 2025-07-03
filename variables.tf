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
  description = "Admin password for Autonomous Database"
  type        = string
  sensitive   = true
}

variable "adb_cpu_core_count" {
  description = "CPU core count for ADB (only used when not in free tier)"
  type        = number
  default     = 1
}

variable "adb_data_storage_size_in_tbs" {
  description = "Storage size in TBs for ADB (only used when not in free tier)"
  type        = number
  default     = 1
}

variable "compute_shape" {
  description = "Shape for compute instance"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "compute_ocpus" {
  description = "OCPUs for compute"
  type        = number
  default     = 1
}

variable "compute_memory_in_gbs" {
  description = "Memory in GB for compute"
  type        = number
  default     = 8
}
