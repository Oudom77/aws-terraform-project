# Publish CloudNotes to the app bundle bucket. Run from the repo root:
#   .\app\deploy\publish.ps1
# Prereqs: terraform apply has created the bucket (any order is fine —
# booting instances retry until app.zip appears).
$ErrorActionPreference = "Stop"

$bucket = terraform output -raw app_bucket
if (-not $bucket) { throw "No app_bucket output - run terraform apply first" }

Compress-Archive -Path app\server.js, app\package.json, app\public -DestinationPath app.zip -Force
aws s3 cp app.zip "s3://$bucket/app.zip"
Remove-Item app.zip -Confirm:$false

Write-Host ""
Write-Host "Published. New instances pick this up automatically."
Write-Host "To roll RUNNING instances onto it now:"
Write-Host "  aws autoscaling start-instance-refresh --auto-scaling-group-name project-cloud-asg"
