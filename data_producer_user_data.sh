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
echo 'export S3_DATA_BUCKET="${S3_DATA_BUCKET}"' >> /home/ec2-user/.bash_profile
echo 'export S3_DATA_PRODUCER_PATH="${S3_DATA_PRODUCER_PATH}"' >> /home/ec2-user/.bash_profile
echo 'export S3_KAFKA_PACKAGE_PATH="${S3_KAFKA_PACKAGE_PATH}"' >> /home/ec2-user/.bash_profile
echo 'export BOOTSTRAP_SERVERS="${BOOTSTRAP_SERVERS}"' >> /home/ec2-user/.bash_profile
echo 'export SECURITY_PROTOCOL="${SECURITY_PROTOCOL}"' >> /home/ec2-user/.bash_profile

# Download the confluent-kafka wheel file from S3
aws s3 cp s3://${S3_DATA_BUCKET}/${S3_KAFKA_PACKAGE_PATH} /home/ec2-user/${S3_KAFKA_PACKAGE_PATH}

# Make sure the package is executable
chmod +x /home/ec2-user/${S3_KAFKA_PACKAGE_PATH}

# Install the confluent-kafka package from the wheel file
pip3 install /home/ec2-user/${S3_KAFKA_PACKAGE_PATH}

# Download the Python script from S3
aws s3 cp s3://${S3_DATA_BUCKET}/${S3_DATA_PRODUCER_PATH} /home/ec2-user/data_producer.py

# Make sure the script is executable
chmod +x /home/ec2-user/data_producer.py

# Run the script once to test it
python3 /home/ec2-user/data_producer.py

# Add cron jobs to the crontab for the ec2-user
# Run every minute and at reboot
(crontab -l 2>/dev/null; echo "* * * * * /usr/bin/python3 /home/ec2-user/data_producer.py >> /home/ec2-user/data_producer.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "@reboot /usr/bin/python3 /home/ec2-user/data_producer.py >> /home/ec2-user/data_producer.log 2>&1") | crontab -
