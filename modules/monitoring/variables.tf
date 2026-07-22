variable "project_name" {
  description = "Short name used as a prefix on every resource"
  type        = string
}

variable "asg_name" {
  description = "Autoscaling group to monitor"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN for ALB health monitoring"
  type        = string
}

variable "load_balancer_arn_suffix" {
  description = "Load balancer ARN suffix for ALB CloudWatch dimensions"
  type        = string
}

variable "cpu_alarm_threshold" {
  description = "CPU percentage threshold"
  type        = number
  default     = 80
}

variable "min_healthy_instances" {
  description = "Minimum healthy instances expected"
  type        = number
  default     = 2
}

variable "alert_email" {
  description = "Optional email for SNS notifications"
  type        = string
  default     = ""
}
