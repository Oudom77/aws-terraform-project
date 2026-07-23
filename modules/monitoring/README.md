# Monitoring Module

Creates an SNS alerts topic, optional email subscription, CloudWatch alarms,
and a dashboard for the compute layer. It monitors average EC2 CPU, in-service
Auto Scaling instances, and unhealthy ALB targets.

The root module supplies the Auto Scaling Group name plus ALB and target-group
metric dimensions. Compute must enable the `GroupInServiceInstances` metric.
