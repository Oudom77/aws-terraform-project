# ─────────────────────────────────────────────────────────────────────────────
# COMPUTE MODULE, part 2 — the self-healing compute layer
#
# High availability: instances spread across 2 AZs behind the ALB (alb.tf).
# Auto recovery:     ASG uses ELB health checks — if an instance stops answering
#                    HTTP, it is terminated and replaced automatically. That is
#                    the failure demo: terminate one instance and watch the ASG
#                    launch a replacement.
# Scalability:       target-tracking policy adds instances when average CPU
#                    exceeds 50%, up to asg_max_size.
# ─────────────────────────────────────────────────────────────────────────────

# Latest Amazon Linux 2023 AMI, resolved at plan time — never hardcode AMI IDs
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── Launch template: the recipe every ASG instance is built from ────────────

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.app_sg_id]

  # Person 4's SSM role plugs in here once it exists
  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name == "" ? [] : [1]
    content {
      name = var.iam_instance_profile_name
    }
  }

  # Require IMDSv2 — blocks SSRF-style credential theft from the metadata API
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  # Install Apache and serve a page that names the instance and AZ, so the
  # load-balancing and failure-recovery demos are visible in the browser.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y httpd
    TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
    INSTANCE_ID=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
    AZ=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
    cat > /var/www/html/index.html <<HTML
    <html><body style="font-family:sans-serif;text-align:center;padding-top:15%">
      <h1>${var.project_name}</h1>
      <p>Served by instance <b>$INSTANCE_ID</b> in <b>$AZ</b></p>
      <p>Refresh to see the load balancer alternate between instances.</p>
    </body></html>
    HTML
    systemctl enable --now httpd
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-app" }
  }
}

# ── Auto Scaling Group ───────────────────────────────────────────────────────

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-asg"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  vpc_zone_identifier = var.app_subnet_ids # private subnets, both AZs

  # "ELB" = replace instances that fail HTTP health checks, not just ones
  # whose hardware dies. This is what makes the failure demo work.
  health_check_type         = "ELB"
  health_check_grace_period = 120

  target_group_arns = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Roll instances automatically when the launch template changes
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app"
    propagate_at_launch = true
  }
}

# Scale out when average CPU across the ASG passes 50%, scale back in when it
# drops. Demo with: stress-ng or a curl loop against the ALB.
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${var.project_name}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}
