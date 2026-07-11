# Pins Terraform and provider versions so the whole team gets identical behavior.
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # any 5.x, but not 6.x (avoids surprise breaking changes)
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Every resource gets these tags automatically — great for the cost report
  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}
