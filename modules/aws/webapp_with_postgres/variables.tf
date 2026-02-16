variable "region" {
  description = "AWS Region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "environment_name" {
  description = "Name prefix for resources"
  type        = string
  default     = "my-app"
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

variable "web_instance_type" {
  description = "Instance type for the Web App"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_type" {
  description = "Instance type for the Postgres DB"
  type        = string
  default     = "t3.medium"
}
