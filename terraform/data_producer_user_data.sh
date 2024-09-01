#!/bin/bash

# Update system packages
sudo yum update -y

# Install Python 3, pip, git, and cronie
sudo yum install -y python3 python3-pip git cronie

# Start and enable the cron service
service crond start
chkconfig crond on

# Add environment variables to .bash_profile (optional) for debugging
echo 'export GITHUB_REPO_URL="${GITHUB_REPO_URL}"' >> /home/ec2-user/.bash_profile
echo 'export CLONE_DIR="${CLONE_DIR}"' >> /home/ec2-user/.bash_profile
echo 'export BOOTSTRAP_SERVERS="${BOOTSTRAP_SERVERS}"' >> /home/ec2-user/.bash_profile
echo 'export SECURITY_PROTOCOL="${SECURITY_PROTOCOL}"' >> /home/ec2-user/.bash_profile
echo 'export TOPIC_NAME="${TOPIC_NAME}"' >> /home/ec2-user/.bash_profile


source /home/ec2-user/.bash_profile

# Clone the repository containing the data producer script
git clone "${GITHUB_REPO_URL}" "${CLONE_DIR}"

# Navigate to the cloned repository directory
cd "${CLONE_DIR}" || exit

# git checkout develop # dev

# Install requirements
pip3 install -r code/producer/requirements.txt

# Ensure the script is executable
sudo chmod +x code/producer/data_producer.py

# Run the script once to test it, passing the environment variables as arguments
python3 code/producer/data_producer.py "${BOOTSTRAP_SERVERS}" "${SECURITY_PROTOCOL}" "${SKYSCANNER_API_KEY}" "${TOPIC_NAME}"

# Add cron jobs to the crontab for the ec2-user
# Run every x minutes and at reboot, passing the environment variables as arguments
(crontab -l 2>/dev/null; echo "* * * * * /usr/bin/python3 "${CLONE_DIR}"/code/producer/data_producer.py \"${BOOTSTRAP_SERVERS}\" \"${SECURITY_PROTOCOL}\" \"${SKYSCANNER_API_KEY}\" \"${TOPIC_NAME}\"  >> /home/ec2-user/data_producer.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "@reboot /usr/bin/python3 "${CLONE_DIR}"/code/producer/data_producer.py \"${BOOTSTRAP_SERVERS}\" \"${SECURITY_PROTOCOL}\" \"${SKYSCANNER_API_KEY}\" \"${TOPIC_NAME}\" >> /home/ec2-user/data_producer.log 2>&1") | crontab -
