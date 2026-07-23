# ─────────────────────────────────────────────────────────────────────────────
# REMOTE STATE
#
# Terraform tracks what it built in a "state file". By default that lives on
# YOUR laptop, which breaks teamwork (5 people = 5 conflicting states).
# Remote state puts it in a shared S3 bucket instead.
#
# The team bucket is already provisioned in Singapore with versioning,
# encryption, public-access blocking, and lock-file support enabled.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  backend "s3" {
    bucket       = "cadt-team1-aws-cloud-tfstate"
    key          = "terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true # stops two people running apply at the same time
  }
}
