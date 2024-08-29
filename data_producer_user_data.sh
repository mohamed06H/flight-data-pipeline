#!/bin/bash

# Update system packages
yum update -y

# Install Python 3, pip, git, and cronie
sudo yum install -y python3 python3-pip git cronie

# Start and enable the cron service
service crond start
chkconfig crond on

# Add environment variables to .bash_profile (optional)
echo 'export GITHUB_REPO_URL="${GITHUB_REPO_URL}"' >> /home/ec2-user/.bash_profile
echo 'export CLONE_DIR="${CLONE_DIR}"' >> /home/ec2-user/.bash_profile
echo 'export BOOTSTRAP_SERVERS="${BOOTSTRAP_SERVERS}"' >> /home/ec2-user/.bash_profile
echo 'export SECURITY_PROTOCOL="${SECURITY_PROTOCOL}"' >> /home/ec2-user/.bash_profile

source /home/ec2-user/.bash_profile

# Clone the GitHub repository
git clone $GITHUB_REPO_URL $CLONE_DIR

# Navigate to the cloned repository directory
cd $CLONE_DIR

git checkout develop # debug

# Make sure the package is executable
chmod +x confluent_kafka_package/*.whl

# Install the confluent-kafka package from the wheel file
pip3 install confluent_kafka_package/*.whl

# Ensure the script is executable
chmod +x code/data_producer.py

# Run the script once to test it, passing the environment variables as arguments
python3 code/data_producer.py "${BOOTSTRAP_SERVERS}" "${SECURITY_PROTOCOL}"

# Add cron jobs to the crontab for the ec2-user
# Run every minute and at reboot, passing the environment variables as arguments
(crontab -l 2>/dev/null; echo "* * * * * /usr/bin/python3 $CLONE_DIR/code/data_producer.py \"${BOOTSTRAP_SERVERS}\" \"${SECURITY_PROTOCOL}\" >> /home/ec2-user/data_producer.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "@reboot /usr/bin/python3 $CLONE_DIR/code/data_producer.py \"${BOOTSTRAP_SERVERS}\" \"${SECURITY_PROTOCOL}\" >> /home/ec2-user/data_producer.log 2>&1") | crontab -
