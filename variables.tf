variable "tenancy_ocid" {
  description = "Tenancy OCID"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
}

variable "compartment_ocid" {
  description = "Compartment OCID"
  type        = string
}

variable "admin_password" {
  description = "Database admin password"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "instance_shape" {
  description = "Compute instance shape"
  type        = string
  default     = "VM.Standard.E2.1.Micro"
}