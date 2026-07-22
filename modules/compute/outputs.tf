# What the rest of the team needs from the compute layer.

output "alb_dns_name" {
  description = "Public URL of the app (deliverable #1)"
  value       = aws_lb.app.dns_name
}

output "target_group_arn" {
  description = "For the ASG registration and Person 4's ALB health alarms"
  value       = aws_lb_target_group.app.arn
}

output "asg_name" {
  description = "For Person 4's CloudWatch alarms and the failure demo"
  value       = aws_autoscaling_group.app.name
}

output "launch_template_id" {
  description = "Launch template driving the ASG"
  value       = aws_launch_template.app.id
}

output "app_bucket" {
  description = "S3 bucket holding the deployable app.zip (used by publish.ps1)"
  value       = aws_s3_bucket.app_bundle.bucket
}

output "instance_role_name" {
  description = "IAM role on the app instances — Person 4 attaches SSM/CloudWatch policies here"
  value       = aws_iam_role.app_instance.name
}
