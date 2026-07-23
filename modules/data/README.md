# Data Module

Owns the private MySQL RDS instance, its database subnet group and credentials
secret, plus the private S3 bucket used for note images. RDS accepts MySQL only
from the application security group supplied by the network module.

The module exposes the database endpoint, database name, secret ARN, and uploads
bucket name/ARN. The root module passes those values to compute; it never passes
the secret value itself.
