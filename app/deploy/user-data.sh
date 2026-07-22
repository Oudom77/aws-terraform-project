#!/bin/bash
# CloudNotes boot script — rendered by templatefile() in modules/compute/asg.tf
# (app_bucket / database_url / s3_bucket are filled in by Terraform).
#
# Installs Node, pulls app.zip from the bundle bucket (instance role provides
# credentials), and runs the app as a systemd service on port 80.
#
# The download RETRIES until the bundle exists, so `terraform apply` and
# app/deploy/publish.ps1 can run in either order. Logs: /var/log/cloud-init-output.log
set -x

dnf install -y nodejs npm unzip

until aws s3 cp "s3://${app_bucket}/app.zip" /tmp/app.zip; do
  echo "app.zip not in s3://${app_bucket} yet - run publish.ps1; retrying in 15s"
  sleep 15
done

mkdir -p /opt/app
unzip -o /tmp/app.zip -d /opt/app
cd /opt/app
npm install --omit=dev --no-audit --no-fund

# Runtime configuration — the same env vars the app reads on a laptop
cat > /etc/app.env <<ENV
DATABASE_URL=${database_url}
S3_BUCKET=${s3_bucket}
PORT=80
ENV

cat > /etc/systemd/system/app.service <<'UNIT'
[Unit]
Description=CloudNotes node app
After=network.target

[Service]
WorkingDirectory=/opt/app
EnvironmentFile=/etc/app.env
ExecStart=/usr/bin/node server.js
Restart=always

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now app.service
