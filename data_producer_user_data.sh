#!/bin/bash

# Update system packages
yum update -y

# Install the cron service (cronie package)
yum install -y cronie

# Start and enable the cron service
service crond start
chkconfig crond on

# Install Python 3 and pip
sudo yum install -y python3 python3-pip

# Add environment variables to .bash_profile
echo 'export GITHUB_REPO_URL="${GITHUB_REPO_URL}"' >> /home/ec2-user/.bash_profile
echo 'export CLONE_DIR="${CLONE_DIR}"' >> /home/ec2-user/.bash_profile
echo 'export BOOTSTRAP_SERVERS="${BOOTSTRAP_SERVERS}"' >> /home/ec2-user/.bash_profile
echo 'export SECURITY_PROTOCOL="${SECURITY_PROTOCOL}"' >> /home/ec2-user/.bash_profile

source /home/ec2-user/.bash_profile


# Clone the GitHub repository
#GITHUB_REPO_URL="https://github.com/mohamed06H/flight-data-pipeline.git"
#CLONE_DIR="/home/ec2-user/flight-data-pipeline"
git clone $GITHUB_REPO_URL $CLONE_DIR

# Navigate to the cloned repository directory
cd $CLONE_DIR

# Make sure the package is executable
chmod +x $CLONE_DIR/confluent_kafka_package/*.whl

# Install the confluent-kafka package from the wheel file
pip3 install $CLONE_DIR/confluent_kafka_package/*.whl

# Ensure the script is executable
chmod +x data_producer.py

# Run the script once to test it
python3 data_producer.py

# Add cron jobs to the crontab for the ec2-user
# Run every minute and at reboot
(crontab -l 2>/dev/null; echo "* * * * * /usr/bin/python3 $CLONE_DIR/data_producer.py >> /home/ec2-user/data_producer.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "@reboot /usr/bin/python3 $CLONE_DIR/data_producer.py >> /home/ec2-user/data_producer.log 2>&1") | crontab -