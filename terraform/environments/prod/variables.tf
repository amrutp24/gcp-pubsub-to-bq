variable "project" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "credentials_file" {
  description = "Path to service account JSON (optional)"
  type        = string
  default     = ""
}

variable "state_bucket" {
  description = "GCS bucket for Terraform state"
  type        = string
}
