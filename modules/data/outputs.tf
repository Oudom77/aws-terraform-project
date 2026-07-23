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

# Added by Person 2 for the compute module's Secrets Manager integration:
# compute grants its instance role read access to this ARN and the instances
# fetch the DB credentials at boot (see modules/compute/iam.tf + user-data.sh).
output "db_secret_arn" {
  description = "ARN of the DB credentials secret, consumed by the compute module."
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "database_url" {
  description = "Complete MySQL connection string."
  value       = "mysql://${aws_db_instance.mysql.endpoint}:3306/${aws_db_instance.mysql.db_name}"
  sensitive   = true
}