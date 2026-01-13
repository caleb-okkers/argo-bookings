variable "aws_region" {
  default = "eu-west-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "argo-bookings"
}
