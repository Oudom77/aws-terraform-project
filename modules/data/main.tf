# Provision the application's data layer, including a private MySQL RDS database and an S3 bucket for uploaded note images.

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.db_subnet_ids
  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier = "${var.project_name}-db"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"
  db_name  = "appdb"
  username = jsondecode(aws_secretsmanager_secret_version.db_credentials.secret_string).username
  password = jsondecode(aws_secretsmanager_secret_version.db_credentials.secret_string).password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]
  publicly_accessible     = false
  multi_az                = false
  backup_retention_period = 0
  deletion_protection     = false
  skip_final_snapshot     = true
  tags = {
    Name = "${var.project_name}-db"
  }
}

resource "aws_s3_bucket" "uploads" {
  bucket = "${var.project_name}-uploads"
  tags = {
    Name = "${var.project_name}-uploads"
  }
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}