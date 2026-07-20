# ─────────────────────────────────────────────────────────────────────────────
# APP DEPLOYMENT — how CloudNotes gets onto the (disposable) instances
#
#   publish.ps1 zips app/ -> S3 bundle bucket -> every new instance's
#   user data downloads and runs it (see app/deploy/user-data.sh)
#
# This is ONLY the deployment plumbing for the compute layer. The app's DATA
# stays Person 3's: RDS for notes, a separate uploads bucket for images.
# Person 4 can attach SSM/CloudWatch policies to the role below.
# ─────────────────────────────────────────────────────────────────────────────

data "aws_caller_identity" "current" {}

# Private bucket holding app.zip. Account ID suffix = globally unique name.
resource "aws_s3_bucket" "app_bundle" {
  bucket        = "${var.project_name}-app-bundle-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # allow terraform destroy even with app.zip inside

  tags = { Name = "${var.project_name}-app-bundle" }
}

resource "aws_s3_bucket_public_access_block" "app_bundle" {
  bucket                  = aws_s3_bucket.app_bundle.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Least-privilege role for the instances: read the app bundle, nothing else.
resource "aws_iam_role" "app_instance" {
  name = "${var.project_name}-app-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "read_app_bundle" {
  name = "read-app-bundle"
  role = aws_iam_role.app_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.app_bundle.arn}/*"
    }]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-app-profile"
  role = aws_iam_role.app_instance.name
}
