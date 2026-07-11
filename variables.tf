variable "project_name" {
  description = "Short name used as a prefix on every resource"
  type        = string
  default     = "project-cloud"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1" # cheapest + everything available; change if your class uses another
}

variable "vpc_cidr" {
  description = "IP range for the whole VPC (65,536 addresses — plenty)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat" {
  description = "NAT gateway lets private instances reach the internet (updates, packages). ~$1/day — set false during development to run free."
  type        = bool
  default     = true
}
