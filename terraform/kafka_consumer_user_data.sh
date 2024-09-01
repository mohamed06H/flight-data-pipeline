#!/bin/bash

# Update system packages
sudo yum update -y

# Install necessary packages
sudo yum install -y python3 python3-pip git

# Set environment variables
echo 'export GITHUB_REPO_URL="${GITHUB_REPO_URL}"' >> /home/ec2-user/.bash_profile
echo 'export CLONE_DIR="${CLONE_DIR}"' >> /home/ec2-user/.bash_profile
echo 'export BOOTSTRAP_SERVERS="${BOOTSTRAP_SERVERS}"' >> /home/ec2-user/.bash_profile
echo 'export SECURITY_PROTOCOL="${SECURITY_PROTOCOL}"' >> /home/ec2-user/.bash_profile
echo 'export TOPIC_NAME="${TOPIC_NAME}"' >> /home/ec2-user/.bash_profile
echo 'export S3_BUCKET_NAME="${S3_BUCKET_NAME}"' >> /home/ec2-user/.bash_profile

source /home/ec2-user/.bash_profile

# Clone the repository containing the Kafka consumer script
git clone "${GITHUB_REPO_URL}" "${CLONE_DIR}"

# Navigate to the cloned repository directory
cd "${CLONE_DIR}" || exit

# git checkout develop # dev

# Install requirements
pip3 install -r code/consumer/requirements.txt

# Ensure the script is executable
sudo chmod +x code/consumer/kafka_to_s3_consumer.py

# Create the log file and ensure it is writable
echo "--- Log file for kafka consumer ---" >> /home/ec2-user/kafka_consumer.log
sudo chmod 666 /home/ec2-user/kafka_consumer.log

# Start the consumer in the background
nohup python3 code/consumer/kafka_to_s3_consumer.py "${BOOTSTRAP_SERVERS}" "${SECURITY_PROTOCOL}" "${TOPIC_NAME}" "${S3_BUCKET_NAME}" >> /home/ec2-user/kafka_consumer.log 2>&1 &
