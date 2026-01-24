# argo-bookings


Architecture

ALB → EC2 ASG → Docker → RDS

VPC public/private subnets

Deployment

terraform init/apply

ECR build/push

ASG refresh

URLs

API: http://booking-alb-1759228622.eu-west-1.elb.amazonaws.com

Security

Private RDS

SG isolation

IAM roles

Known gaps

Frontend hosting

HTTPS

CI/CD automation

CloudWatch logs