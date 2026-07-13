# Root outputs — printed after `terraform apply`, and usable by teammates.
# Person 2 will add the ALB DNS name here later.

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
