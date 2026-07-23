variable "project_name" {
  description = "Short name used as a prefix on every resource"
  type        = string
  default     = "project-cloud"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1" # Asia hehe :p
}

variable "vpc_cidr" {
  description = "IP range for the whole VPC (65,536 addresses — plenty)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat" {
  description = "NAT gateway required by the current EC2 bootstrap for packages and AWS API access."
  type        = bool
  default     = true
}
