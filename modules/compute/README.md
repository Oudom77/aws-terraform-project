# Compute Module

Runs CloudNotes on private EC2 instances behind a public Application Load
Balancer. The Auto Scaling Group spans two availability zones and uses a launch
template with IMDSv2, an instance role, and SSM Session Manager access.

The module also owns the private deployment bucket for `app.zip`. Its instance
role can read that bundle, retrieve the configured database secret, and manage
objects in the data module's uploads bucket.

Key outputs are the ALB DNS name, target group identifiers, Auto Scaling Group
name, launch template ID, and deployment bucket name.
