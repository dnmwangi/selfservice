#! /bin/bash
sudo yum update -y

# Ensure root user is able to login
# This is a pre-requisite for ansible automation platform installer
existing=$(sudo cat /root/.ssh/authorized_keys)
new=${existing:165}
sudo echo $new > /root/.ssh/authorized_keys
