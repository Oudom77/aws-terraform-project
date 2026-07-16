# What the rest of the team needs from the compute layer.

output "alb_dns_name" {
  description = "Public URL of the app (deliverable #1)"
  value       = aws_lb.app.dns_name
}

output "target_group_arn" {
  description = "For the ASG registration and Person 4's ALB health alarms"
  value       = aws_lb_target_group.app.arn
}
