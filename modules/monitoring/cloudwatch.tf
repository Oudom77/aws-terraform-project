# CloudWatch alarms + dashboard for the compute layer.

data "aws_region" "current" {}

locals {
  # CloudWatch dimensions expect.
  target_group_arn_suffix = element(
    split(":", var.target_group_arn),
    length(split(":", var.target_group_arn)) - 1
  )
}

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# 1. High CPU across the ASG
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "Average CPU across the ASG is above ${var.cpu_alarm_threshold}% for 10 minutes"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# 2. Fewer instances InService than expected — this is your failure-demo evidence
resource "aws_cloudwatch_metric_alarm" "low_instance_count" {
  alarm_name          = "${var.project_name}-low-healthy-instances"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "Average"
  threshold           = var.min_healthy_instances
  alarm_description   = "Fewer than ${var.min_healthy_instances} instances are InService"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# 3. ALB target failing health checks
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${var.project_name}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "One or more targets behind the ALB are failing health checks"

  dimensions = {
    LoadBalancer = var.load_balancer_arn_suffix
    TargetGroup  = local.target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# Dashboard combining all three
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title   = "ASG CPU Utilization"
          metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name]]
          period  = 300
          stat    = "Average"
          region  = data.aws_region.current.name
          view    = "timeSeries"
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title   = "In-Service Instances"
          metrics = [["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.asg_name]]
          period  = 60
          stat    = "Average"
          region  = data.aws_region.current.name
          view    = "timeSeries"
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title   = "Unhealthy Targets (ALB)"
          metrics = [["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", var.load_balancer_arn_suffix, "TargetGroup", local.target_group_arn_suffix]]
          period  = 60
          stat    = "Average"
          region  = data.aws_region.current.name
          view    = "timeSeries"
        }
      }
    ]
  })
}
