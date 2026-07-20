output "ec2_instance_profile_name" {
  description = "Attach this to the launch template so instances get SSM access"
  value       = aws_iam_instance_profile.ec2_ssm.name
}

output "ec2_role_arn" {
  value = aws_iam_role.ec2_ssm.arn
}