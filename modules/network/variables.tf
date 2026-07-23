variable "project_name" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "IP range for the VPC"
  type        = string
}

variable "enable_nat" {
  description = "Whether to create the NAT gateway required by the current app bootstrap"
  type        = bool
}
