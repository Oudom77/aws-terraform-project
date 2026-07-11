# ─────────────────────────────────────────────────────────────────────────────
# REMOTE STATE — read this before uncommenting!
#
# Terraform tracks what it built in a "state file". By default that lives on
# YOUR laptop, which breaks teamwork (5 people = 5 conflicting states).
# Remote state puts it in a shared S3 bucket instead.
#
# CHICKEN-AND-EGG: Terraform can't store state in a bucket that doesn't exist
# yet. So ONE person (you, Person 1) creates the bucket manually, ONCE:
#
#   aws s3api create-bucket --bucket <TEAM>-project-cloud-tfstate --region us-east-1
#   aws s3api put-bucket-versioning --bucket <TEAM>-project-cloud-tfstate \
#       --versioning-configuration Status=Enabled
#
# (Versioning = undo button if the state ever gets corrupted.)
#
# Then replace <TEAM> below, uncomment the block, and run `terraform init`.
# Everyone who clones the repo after that is automatically on shared state.
# ─────────────────────────────────────────────────────────────────────────────

# terraform {
#   backend "s3" {
#     bucket       = "<TEAM>-project-cloud-tfstate"
#     key          = "terraform.tfstate"
#     region       = "us-east-1"
#     use_lockfile = true # stops two people running apply at the same time
#   }
# }
