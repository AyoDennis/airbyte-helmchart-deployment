# Production-grade Airbyte Deployment on Kubernetes

A comprehensive guide for deploying Airbyte on AWS using Kubernetes (Minikube), Terraform, and externalized storage for a production-ready, highly available, and cost-efficient setup.

## Overview

This project demonstrates how to move from a basic Docker-Compose Airbyte deployment to a robust Kubernetes environment with external database storage, advanced security, and production-grade logging.

> **Note**: This setup uses Minikube for demonstration purposes. For actual production deployments, consider using Amazon EKS or other managed Kubernetes services.

## Architecture Components

### Infrastructure & Tools
- **Terraform** - Infrastructure as Code for resource provisioning
- **AWS S3** - External logging and Terraform statefile locking
- **AWS IAM** - Identity and Access Management
- **AWS VPC** - Virtual Private Cloud for networking
- **AWS VPN** - Secure access to resources
- **AWS RDS** - External PostgreSQL database for metadata
- **Amazon EC2** - Virtual machine hosting Minikube

### Kubernetes Stack
- **Docker** - Container runtime
- **Minikube** - Local Kubernetes environment
- **K9s** - Cluster monitoring and visualization
- **Kubectl** - Kubernetes command-line tool
- **Helm** - Kubernetes package manager
- **External Secrets Operator (ESO)** - Advanced secrets management

### Application
- **Airbyte** - Open-source data integration platform
- **Ngrok** - External access tunneling

## 📋 Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured with your credentials
- Terraform installed locally
- Basic understanding of Kubernetes and Docker

## Setup Instructions

### 1. Infrastructure Provisioning

#### Clone and Setup
```bash
git clone <your-repository-url>
cd airbyte-k8s-deployment
```

#### Configure Terraform Backend
Update `backend.tf` with your S3 bucket details:
```hcl
terraform {
  backend "s3" {
    bucket       = "your-airbyte-project-bucket"
    key          = "key/terraform.tfstate"
    use_lockfile = true
    region       = "eu-central-1"
    profile      = "default"
  }
}
```

#### Generate VPN Certificates
```bash
# Clone OpenVPN easy-rsa
git clone https://github.com/OpenVPN/easy-rsa.git
cd easy-rsa/easyrsa3

# Initialize PKI
./easyrsa init-pki

# Build CA
./easyrsa build-ca nopass

