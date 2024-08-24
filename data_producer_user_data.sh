#!/bin/bash

# Update system packages
yum update -y

# Install Python 3 and pip
yum install -y python3 python3-pip

# Install required Python packages
pip3 install confluent_kafka

# Use environment variables for S3 bucket and path
S3_DATA_BUCKET="${S3_DATA_BUCKET}"
S3_USER_DATA_PATH="${S3_USER_DATA_PATH}"

# Echo values for debugging
echo "Using S3 bucket: S3_DATA_BUCKET"
echo "Using S3 path: S3_USER_DATA_PATH"

# Download the Python script from S3
aws s3 cp s3://S3_DATA_BUCKET/S3_USER_DATA_PATH /home/ec2-user/data_producer.py

# Execute the Python script using environment variables
# export BOOTSTRAP_SERVERS="${BOOTSTRAP_SERVERS}"
# export SECURITY_PROTOCOL="${SECURITY_PROTOCOL}"
# python3 /home/ec2-user/data_producer.py

# Create a systemd service for the script
cat << EOF > /etc/systemd/system/data_producer.service
[Unit]
Description=Data Producer Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/ec2-user/data_producer.py
WorkingDirectory=/home/ec2-user
Environment="BOOTSTRAP_SERVERS=${BOOTSTRAP_SERVERS}"
Environment="SECURITY_PROTOCOL=${SECURITY_PROTOCOL}"
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the systemd service
systemctl daemon-reload
systemctl enable data_producer.service
systemctl start data_producer.service
