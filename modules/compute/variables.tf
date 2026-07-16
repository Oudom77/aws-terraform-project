# Inputs for the compute module — wired from the network module in root main.tf.

variable "project_name" {
  description = "Short name used as a prefix on every resource"
  type        = string
}

variable "vpc_id" {
  description = "VPC to create the target group in"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets — the ALB lives here (one per AZ)"
  type        = list(string)
}

variable "app_subnet_ids" {
  description = "Private app subnets — EC2 instances live here (one per AZ)"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group for the load balancer"
  type        = string
}

variable "app_sg_id" {
  description = "Security group for the app instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for app servers"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum number of instances (2 = one per AZ for high availability)"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Ceiling the ASG can scale out to under load"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "How many instances to run normally"
  type        = number
  default     = 2
}

variable "iam_instance_profile_name" {
  description = "Instance profile for SSM access etc. (Person 4 provides this later; empty = none)"
  type        = string
  default     = ""
}
