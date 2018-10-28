#!/bin/bash
echo 'test' > /home/ec2-user/user-script-output.txt

sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user
docker run --rm -p 3000:3000 -d arnaudmgh/synergy-screen-app
