#!/bin/bash
# CloudNotes boot script — rendered by templatefile() in modules/compute/asg.tf
# (app_bucket / db_secret_arn / db_endpoint / db_name / s3_bucket are filled in
# by Terraform).
#
# Installs Node, pulls app.zip from the bundle bucket (instance role provides
# credentials), and runs the app as a systemd service on port 80.
#
# The download RETRIES until the bundle exists, so `terraform apply` and
# app/deploy/publish.ps1 can run in either order. Logs: /var/log/cloud-init-output.log
set -e

dnf install -y nodejs npm unzip jq

until aws s3 cp "s3://${app_bucket}/app.zip" /tmp/app.zip; do
  echo "app.zip not in s3://${app_bucket} yet - run publish.ps1; retrying in 15s"
  sleep 15
done

mkdir -p /opt/app
unzip -o /tmp/app.zip -d /opt/app || {
  unzip_status=$?
  # Compress-Archive on Windows uses backslash separators. unzip extracts the
  # bundle successfully but returns 1 for that warning.
  [ "$unzip_status" -eq 1 ] || exit "$unzip_status"
}
cd /opt/app
npm install --omit=dev --no-audit --no-fund

# The rendered launch template contains only the secret ARN. The instance uses
# its IAM role to fetch the credentials at boot and assembles the connection
# string locally. Host, port, and database name are non-secret inputs.
DATABASE_URL=""
if [ -n "${db_secret_arn}" ]; then
  until SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "${db_secret_arn}" --query SecretString --output text); do
    echo "secret ${db_secret_arn} not readable yet - retrying in 15s"
    sleep 15
  done
  # @uri percent-encodes the values so special characters survive URL parsing;
  # server.js runs decodeURIComponent() to recover the originals.
  DB_USER=$(echo "$SECRET_JSON" | jq -rj '.username|@uri')
  DB_PASS=$(echo "$SECRET_JSON" | jq -rj '.password|@uri')
  DATABASE_URL="mysql://$DB_USER:$DB_PASS@${db_endpoint}/${db_name}"
fi

# Runtime configuration — readable only by root because it contains DB credentials.
install -m 600 /dev/null /etc/app.env
cat > /etc/app.env <<ENV
DATABASE_URL=$DATABASE_URL
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
