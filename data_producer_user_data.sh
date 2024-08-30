#!/bin/bash

# Update system packages
yum update -y

# Install Python 3, pip, git, and cronie
sudo yum install -y python3 python3-pip git cronie

# Start and enable the cron service
service crond start
chkconfig crond on

# Clone the GitHub repository
git clone "${GITHUB_REPO_URL}" "${CLONE_DIR}"

# Navigate to the cloned repository directory
cd "${CLONE_DIR}" || exit

git checkout develop # dev

# Install requirements
pip3 install -r requirements.txt

# Ensure the script is executable
chmod +x code/data_producer.py

# Run the script once to test it, passing the environment variables as arguments
python3 code/data_producer.py "${BOOTSTRAP_SERVERS}" "${SECURITY_PROTOCOL}" "${SKYSCANNER_API_KEY}"

# Add cron jobs to the crontab for the ec2-user
# Run every x minutes and at reboot, passing the environment variables as arguments
(crontab -l 2>/dev/null; echo "*/3 * * * * /usr/bin/python3 "${CLONE_DIR}"/code/data_producer.py \"${BOOTSTRAP_SERVERS}\" \"${SECURITY_PROTOCOL}\" \"${SKYSCANNER_API_KEY}\"  >> /home/ec2-user/data_producer.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "@reboot /usr/bin/python3 "${CLONE_DIR}"/code/data_producer.py \"${BOOTSTRAP_SERVERS}\" \"${SECURITY_PROTOCOL}\" \"${SKYSCANNER_API_KEY}\" >> /home/ec2-user/data_producer.log 2>&1") | crontab -
