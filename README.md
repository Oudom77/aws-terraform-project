# Project Cloud — AWS Web App with Terraform

Scalable, secure, highly available web application on AWS, deployed with Terraform.

## Architecture (short version)

- **VPC** across 2 availability zones
- **Public subnets**: Load Balancer (+ NAT gateway)
- **Private app subnets**: EC2 instances in an Auto Scaling Group
- **Private DB subnets**: RDS (no internet access at all)
- Security groups chained least-privilege: internet -> ALB -> app -> DB

## Repo structure

```
project-cloud/
├── app/                # CloudNotes source and EC2 deployment scripts
├── main.tf            # Root — wires the modules together
├── providers.tf       # Terraform + AWS provider versions
├── variables.tf       # Project-wide settings (region, name, NAT toggle)
├── outputs.tf         # Values other people/modules need
├── backend.tf         # Remote state config (read the comments inside!)
└── modules/
    ├── network/       # Person 1 — VPC, subnets, routing, security groups
    ├── compute/       # Person 2 — Launch template, ASG, ALB
    ├── data/          # Person 3 — RDS, S3
    └── monitoring/    # Person 4 — CloudWatch, alarms, dashboard
```

## Getting started (everyone)

1. Install Terraform (developer.hashicorp.com/terraform/install) and the AWS CLI
2. Get AWS credentials and run `aws configure`
3. Clone this repo, then:

```bash
terraform init      # downloads providers, sets up state
terraform plan      # shows what WOULD be created — always read this
terraform apply     # actually creates it (type "yes")
terraform destroy   # tears everything down — RUN THIS WHEN DONE WORKING
```

**Money rule: `terraform destroy` at the end of every work session.**
The NAT gateway alone costs roughly $1/day if you forget. Keep `enable_nat = true`:
the current EC2 bootstrap needs outbound access for packages, S3, Secrets Manager,
and SSM. Disabling it requires a different deployment strategy and VPC endpoints.

## Team workflow (GitHub usage is graded!)

1. Never commit directly to `main`
2. `git checkout -b feature/your-thing` -> work -> commit -> push
3. Open a Pull Request; Person 5 reviews and merges
4. Everyone's commits must be their own — graders check this

## Person 1 status

- [x] Repo structure
- [x] VPC + subnets (2 AZs, public/private/db tiers)
- [x] Internet gateway, NAT (toggleable), route tables
- [x] Security groups (ALB / app / DB)
- [x] Remote state bootstrapped in S3 with versioning and state locking
