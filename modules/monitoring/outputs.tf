output "ec2_instance_profile_name" {
  description = "Attach this to the launch template so instances get SSM access"
  value       = aws_iam_instance_profile.ec2_ssm.name
}

output "ec2_role_arn" {
  value = aws_iam_role.ec2_ssm.arn
}

output "sns_topic_arn" {
  description = "Subscribe more people/services to this for alarm notifications"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "Direct link to the CloudWatch dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}