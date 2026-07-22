output "sns_topic_arn" {
  description = "Subscribe more people/services to this for alarm notifications"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "Direct link to the CloudWatch dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}
