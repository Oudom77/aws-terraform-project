output "db_endpoint" {
  description = "RDS endpoint."
  value       = aws_db_instance.mysql.endpoint
}

output "db_name" {
  description = "Database name."
  value       = aws_db_instance.mysql.db_name
}

output "uploads_bucket" {
  description = "Private S3 bucket name."
  value       = aws_s3_bucket.uploads.bucket
}

output "database_url" {
  description = "Complete MySQL connection string."
  value       = "mysql://${aws_db_instance.mysql.endpoint}:3306/${aws_db_instance.mysql.db_name}"
  sensitive   = true
}