# ─────────────────────────────────────────────────────────────────────────────
# COMPUTE MODULE, part 1 — the load balancer (public front door)
#
#   internet ──> ALB (public subnets, 2 AZs) ──> target group ──> instances
#
# The ASG in asg.tf registers its instances into the target group below.
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_lb" "app" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids # one per AZ = survives an AZ outage
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Fast liveness checks so the failure demo shows recovery within ~1 minute.
  # Database readiness is exposed separately at /ready.
  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
