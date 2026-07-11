# ─────────────────────────────────────────────────────────────────────────────
# SECURITY GROUPS — the least-privilege chain
#
#   internet ──80──> ALB ──80──> app instances ──3306──> RDS
#
# Each tier ONLY accepts traffic from the tier in front of it, by referencing
# that tier's security group (not IP ranges). This is the "network isolation"
# the rubric wants — be ready to explain it in the presentation.
# ─────────────────────────────────────────────────────────────────────────────

# ALB: the only thing exposed to the internet
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Load balancer - accepts HTTP from anywhere"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound (to reach the app instances)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

# App instances: ONLY the ALB can talk to them. No SSH from the internet —
# use AWS SSM Session Manager if you need a shell (Person 4 sets up the role).
resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "App instances - accepts HTTP only from the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from the load balancer only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # <- SG reference, not an IP
  }

  egress {
    description = "Outbound for package installs (via NAT) and AWS APIs"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-app-sg" }
}

# Database: ONLY app instances can connect, only on the MySQL port.
# Change 3306 -> 5432 if Person 3 picks PostgreSQL.
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "RDS - accepts MySQL only from app instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from app tier only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # No egress rules at all: the DB never initiates outbound connections.
  tags = { Name = "${var.project_name}-db-sg" }
}
