variable "project_name" {
  description = "Project name prefix."
  type        = string
}

variable "db_subnet_ids" {
  description = "Database subnet IDs from the Network module."
  type        = list(string)
}

variable "db_sg_id" {
  description = "Database Security Group ID from the Network module."
  type        = string
}

