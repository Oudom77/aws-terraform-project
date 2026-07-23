# IAM resources used by the app instances belong to the compute module.

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

# Allow the app to manage uploaded image objects in its private bucket.
resource "aws_iam_role_policy" "manage_uploads" {
  name = "manage-app-uploads"
  role = aws_iam_role.app_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ]
      Resource = "${var.uploads_bucket_arn}/*"
    }]
  })
}

# Read the DB credentials secret (Person 3's data module) at boot. Scoped to the
# single secret ARN — least privilege.
resource "aws_iam_role_policy" "read_db_secret" {
  name = "read-db-secret"
  role = aws_iam_role.app_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = var.db_secret_arn
    }]
  })
}

# Session Manager provides shell access without opening inbound SSH.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-app-profile"
  role = aws_iam_role.app_instance.name
}
