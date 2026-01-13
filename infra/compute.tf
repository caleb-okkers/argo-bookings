#####################################################
# Launch Template (Free Tier Safe)
#####################################################
data "aws_ssm_parameter" "al2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_launch_template" "backend" {
  name_prefix   = "${var.project_name}-backend-"
  image_id      = data.aws_ssm_parameter.al2_ami.value
  instance_type = "t3.micro"  # Switch from t2.micro

  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(<<EOF
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
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
  health_check_grace_period = 60
  force_delete              = true

  tag {
    key                 = "Name"
    value               = "${var.project_name}-backend"
    propagate_at_launch = true
  }
}
