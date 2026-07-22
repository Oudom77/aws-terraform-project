# Root outputs — printed after `terraform apply`, and usable by teammates.

output "vpc_id" {
  description = "The VPC everything lives in"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnets (ALB, NAT)"
  value       = module.network.public_subnet_ids
}

output "app_subnet_ids" {
  description = "Private subnets for EC2/ASG"
  value       = module.network.app_subnet_ids
}

output "db_subnet_ids" {
  description = "Private subnets for RDS"
  value       = module.network.db_subnet_ids
}

output "app_url" {
  description = "The app's public address — deliverable #1"
  value       = "http://${module.compute.alb_dns_name}"
}

output "asg_name" {
  description = "Auto Scaling Group name (used in the failure demo and Person 4's alarms)"
  value       = module.compute.asg_name
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.monitoring.dashboard_url
}

output "app_bucket" {
  description = "Bucket for app.zip — publish the app with app/deploy/publish.ps1"
  value       = module.compute.app_bucket
}
