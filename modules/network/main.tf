# ─────────────────────────────────────────────────────────────────────────────
# NETWORK MODULE — Person 1
#
# Layout (2 availability zones for high availability):
#   10.0.1.0/24, 10.0.2.0/24   public   — ALB + NAT live here
#   10.0.11.0/24, 10.0.12.0/24 app      — EC2 instances, private
#   10.0.21.0/24, 10.0.22.0/24 database — RDS, private, no internet at all
# ─────────────────────────────────────────────────────────────────────────────

# Ask AWS which availability zones exist in the chosen region
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Use the first two AZs, whatever region we're in
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# The VPC — our private slice of AWS
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # needed so RDS endpoints resolve nicely

  tags = { Name = "${var.project_name}-vpc" }
}

# ── Subnets ──────────────────────────────────────────────────────────────────

# Public: things here can have public IPs and talk to the internet directly
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1) # 10.0.1.0/24, 10.0.2.0/24
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-public-${local.azs[count.index]}" }
}

# App tier: EC2 lives here. No public IPs — only reachable through the ALB.
resource "aws_subnet" "app" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 11) # 10.0.11.0/24, 10.0.12.0/24
  availability_zone = local.azs[count.index]

  tags = { Name = "${var.project_name}-app-${local.azs[count.index]}" }
}

# DB tier: RDS lives here. Fully isolated — no route to the internet, ever.
resource "aws_subnet" "db" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 21) # 10.0.21.0/24, 10.0.22.0/24
  availability_zone = local.azs[count.index]

  tags = { Name = "${var.project_name}-db-${local.azs[count.index]}" }
}

# ── Internet access ──────────────────────────────────────────────────────────

# Internet gateway: the VPC's front door to the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

# NAT gateway: lets PRIVATE instances make OUTBOUND connections (yum/apt
# updates) without being reachable from the internet. One-way valve.
# Costs money, so it's optional via enable_nat.
resource "aws_eip" "nat" {
  count  = var.enable_nat ? 1 : 0
  domain = "vpc"
  tags   = { Name = "${var.project_name}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id # NAT sits in a PUBLIC subnet
  tags          = { Name = "${var.project_name}-nat" }

  depends_on = [aws_internet_gateway.main]
}

# ── Routing ──────────────────────────────────────────────────────────────────

# Public subnets: anything not local goes out the internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# App subnets: outbound traffic goes through the NAT (if enabled).
# If NAT is disabled there's simply no internet route — still deploys fine.
resource "aws_route_table" "app" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-app-rt" }
}

resource "aws_route" "app_nat" {
  count                  = var.enable_nat ? 1 : 0
  route_table_id         = aws_route_table.app.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

resource "aws_route_table_association" "app" {
  count          = 2
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app.id
}

# DB subnets: NO internet route in either direction. Deliberate.
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-db-rt" }
}

resource "aws_route_table_association" "db" {
  count          = 2
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}
