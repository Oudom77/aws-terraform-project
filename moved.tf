# Preserve the SSM attachment if the earlier monitoring-owned configuration
# was applied before instance IAM ownership moved into the compute module.
moved {
  from = module.monitoring.aws_iam_role_policy_attachment.ssm_core
  to   = module.compute.aws_iam_role_policy_attachment.ssm_core
}
