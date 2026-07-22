# Allow app instances to be reached via AWS SSM Session Manager instead of SSH.
# This attaches to the existing app role so deployment S3 permissions stay intact.

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = var.instance_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
