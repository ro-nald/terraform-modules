variable "region" {
  description = "AWS Region to deploy into"
  type        = string
}

variable "application_name" {
  description = "Name prefix for resources"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy into."
  type        = string
  default     = null

  validation {
    condition     = var.vpc_id == null || var.vpc_id == "" || (length(var.vpc_id) > 4 && substr(var.vpc_id, 0, 4) == "vpc-")
    error_message = "The vpc_id value must be a valid AWS VPC ID, starting with \"vpc-\"."
  }
}

variable "instance_type" {
  description = "Instance type for the Web App"
  type        = string
  default     = "t4g.nano"
}

variable "block_volume_type" {
  description = "EBS volume type for the root block device"
  type        = string
  default     = "gp3"
}