# Quickbook — AWS Scalable Web App Infrastructure

This project demonstrates a **production-style, highly available AWS web application** deployed using Infrastructure-as-Code, containerized backend services, managed database storage, CDN frontends, monitoring, and CI/CD automation.

It was built as part of a 1 Month cloud engineering project focusing on:

* Cloud architecture design
* AWS best practices
* Terraform IaC
* Auto-scaling compute
* Secure networking
* Monitoring & cost control
* CI/CD pipelines

---

## Technical Report

https://docs.google.com/document/d/1i4FnxaXYIoZB4V0SG7CNgSFrkv3lVeAX4Qp6J3nUJ1I/edit?usp=sharing

## Presentation

https://www.canva.com/design/DAG_dXp9AyM/OLpjhcTVt-Xl9at7ZxKF4g/edit?utm_content=DAG_dXp9AyM&utm_campaign=designshare&utm_medium=link2&utm_source=sharebutton

## Live Demo

### Frontend

[https://d370h72f8ty4et.cloudfront.net](https://d370h72f8ty4et.cloudfront.net)

### API (HTTPS via CloudFront)

[https://d2irs3t4926chr.cloudfront.net](https://d2irs3t4926chr.cloudfront.net)

Example endpoints:

* `/health`
* `/db-check`
* `/appointments`

---

## Architecture Overview

**Services Used**

* Amazon VPC (public + private subnets)
* Application Load Balancer
* EC2 Auto Scaling Group
* Docker + Amazon ECR
* Amazon RDS MySQL
* Amazon S3 (frontend hosting)
* Amazon CloudFront (frontend + API)
* AWS Systems Manager (SSM)
* AWS Parameter Store
* Amazon CloudWatch
* AWS Budgets
* Terraform
* GitHub Actions (CI/CD)

**High-Level Flow**

1. Users access the SPA frontend through CloudFront.
2. Frontend calls the API CloudFront distribution over HTTPS.
3. API CloudFront forwards to the ALB.
4. ALB routes traffic to EC2 instances running Docker containers.
5. Backend connects securely to RDS MySQL.
6. Auto Scaling Group handles replacement of unhealthy instances.
7. Terraform manages all infrastructure.

---

## Repository Structure

```
.
├── backend/            # Node.js Express API + Dockerfile
├── frontend/           # Vue/Vite SPA
├── infra/              # Terraform IaC
├── .github/workflows/  # CI/CD pipelines
├── README.md
```

---

## Infrastructure (Terraform)

Terraform provisions:

* VPC with:

  * Public subnets for ALB
  * Private subnets for EC2 + RDS
* Security Groups:

  * ALB → Backend on port 4000
  * Backend → RDS on 3306
* EC2 Launch Template
* Auto Scaling Group
* Target Groups + ALB
* RDS MySQL instance
* S3 frontend bucket
* CloudFront frontend distribution
* CloudFront API distribution

Deploy infra:

```bash
terraform init
terraform apply
```

---

## Backend

* Node.js + Express
* Containerized with Docker
* Images stored in ECR
* Pulled automatically by ASG instances
* Secrets fetched from AWS Parameter Store
* CORS restricted to frontend CloudFront domain

Endpoints:

* `/health`
* `/appointments`
* `/db-check`

---

## Frontend

* Vue + Vite SPA
* Built to static assets
* Hosted in S3
* Delivered globally via CloudFront
* API base URL injected at build time

Production build:

```bash
npm run build
aws s3 sync dist s3://<bucket> --delete
```

---

## Monitoring & Cost Controls

Implemented:

* CloudWatch dashboards
* CloudWatch alarms:

  * unhealthy targets
  * RDS storage
* AWS Budget with monthly limit
* Auto-healing via ASG + ALB health checks

---

## CI/CD

GitHub Actions pipelines automate:

### Backend

* Docker build
* Push to ECR
* Instance refresh on ASG

### Frontend

* Build SPA
* Upload to S3
* CloudFront invalidation

---

## Security Design

* Private subnets for compute and database
* SG-to-SG traffic only
* Secrets stored in SSM
* HTTPS via CloudFront
* No direct DB access from public internet
* IAM roles on EC2

---

## Future Improvements

* GitHub OIDC instead of static credentials
* Centralized log shipping to CloudWatch
* Redis caching layer
* WAF integration
* Custom domains + ACM certificates
* Blue/green deployments
* ECS/Fargate migration

---

## Lessons Learned

* Designing private networking early avoids major refactors.
* HTTPS enforcement is critical for modern SPAs.
* CloudFront is useful even for APIs.
* Terraform simplifies repeatable deployments.
* Parameter Store avoids secrets in code.
* Auto Scaling provides resilience at minimal cost.


