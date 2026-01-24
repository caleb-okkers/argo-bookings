#####################################################
# Launch Template (Free Tier Safe)
#####################################################
data "aws_ssm_parameter" "al2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_launch_template" "backend" {
  name_prefix   = "${var.project_name}-backend-"
  image_id      = data.aws_ssm_parameter.al2_ami.value
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(<<EOF
#!/bin/bash
set -e

LOGFILE="/var/log/backend.log"
echo "$(date) - Starting backend instance setup" > $LOGFILE

# Update system and install packages
yum update -y >> $LOGFILE 2>&1
yum install -y awscli docker jq amazon-ssm-agent >> $LOGFILE 2>&1

# Enable and start services
systemctl enable docker amazon-ssm-agent >> $LOGFILE 2>&1
systemctl start docker amazon-ssm-agent >> $LOGFILE 2>&1

echo "$(date) - Docker and SSM agent started" >> $LOGFILE

# Wait until SSM agent is online (optional, ensures instance is manageable)
SSM_STATUS=""
for i in {1..10}; do
  SSM_STATUS=$(aws ssm describe-instance-information \
    --filters "Key=InstanceIds,Values=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" \
    --query "InstanceInformationList[0].PingStatus" \
    --output text || echo "Offline")
  if [ "$SSM_STATUS" = "Online" ]; then
    echo "$(date) - SSM agent online" >> $LOGFILE
    break
  fi
  echo "$(date) - Waiting for SSM agent to be online..." >> $LOGFILE
  sleep 10
done

# Retry loop for ECR login and pull (max 5 attempts)
for i in {1..5}; do
  if aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 653263736678.dkr.ecr.eu-west-1.amazonaws.com >> $LOGFILE 2>&1; then
    echo "$(date) - ECR login successful" >> $LOGFILE
    break
  else
    echo "$(date) - ECR login failed, retrying..." >> $LOGFILE
    sleep 10
  fi
done

# Retry loop to pull Docker image
for i in {1..5}; do
  if docker pull 653263736678.dkr.ecr.eu-west-1.amazonaws.com/argo-bookings-backend:1.0.3 >> $LOGFILE 2>&1; then
    echo "$(date) - Docker image pulled successfully" >> $LOGFILE
    break
  else
    echo "$(date) - Docker pull failed, retrying..." >> $LOGFILE
    sleep 10
  fi
done

# Stop/remove any existing container
docker stop backend || true >> $LOGFILE 2>&1
docker rm backend || true >> $LOGFILE 2>&1

# Fetch DB password from SSM Parameter Store (SecureString)
DB_PASSWORD="$(aws ssm get-parameter --region eu-west-1 --name /argo-bookings/db_password --with-decryption --query Parameter.Value --output text)"

docker run -d --name backend \
  --restart unless-stopped \
  -p 4000:4000 \
  -e DB_HOST=argodatabase-1.cfks4goeo7r5.eu-west-1.rds.amazonaws.com \
  -e DB_USER=admin \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e DB_NAME=bookings \
  -e DB_PORT=3306 \
  -e PORT=4000 \
  653263736678.dkr.ecr.eu-west-1.amazonaws.com/argo-bookings-backend:1.0.3 \
  >> $LOGFILE 2>&1

echo "$(date) - Backend container started" >> $LOGFILE

# Optional: wait for container to be healthy before signaling ready
for i in {1..12}; do
  if curl -s http://localhost:4000/health | grep -q "OK"; then
    echo "$(date) - Backend is responding on /health" >> $LOGFILE
    break
  else
    echo "$(date) - Waiting for backend container to respond..." >> $LOGFILE
    sleep 10
  fi
done
EOF
  )
}

#####################################################
# Auto Scaling Group (1 Free Tier Instance)
#####################################################
resource "aws_autoscaling_group" "backend" {
  desired_capacity = 1
  min_size         = 1
  max_size         = 1
  vpc_zone_identifier = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.backend.arn]

  health_check_type         = "EC2"
  health_check_grace_period = 180
  force_delete              = true

  tag {
    key                 = "Name"
    value               = "${var.project_name}-backend"
    propagate_at_launch = true
  }
}
