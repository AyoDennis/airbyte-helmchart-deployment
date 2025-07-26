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

# Generate server certificate
./easyrsa --san=DNS:server build-server-full server nopass

# Generate client certificate
./easyrsa build-client-full client1.domain.tld nopass

# Copy certificates to project
mkdir ~/custom_folder/
cp pki/ca.crt ~/custom_folder/ 
cp pki/issued/server.crt ~/custom_folder/ 
cp pki/private/server.key ~/custom_folder/ 
cp pki/issued/client1.domain.tld.crt ~/custom_folder 
cp pki/private/client1.domain.tld.key ~/custom_folder/
```

#### Create AWS Secrets
Create a secret in AWS Secrets Manager named `airbyte_eso` with your database credentials:
```json
{
  "database": "airbyte_db",
  "database-user": "airbyte_user",
  "database-password": "your_secure_password"
}
```

#### Deploy Infrastructure
```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

### 2. EC2 Instance Setup

#### Connect via VPN
1. Download the VPN configuration from AWS Console
2. Install AWS VPN Client
3. Connect using the downloaded `.ovpn` file

#### SSH to EC2 Instance
```bash
chmod 400 your-keypair.pem
ssh -i your-keypair.pem ec2-user@<private-ip>
```

#### Install Docker
```bash
sudo yum update -y
sudo yum install docker
sudo service docker start
sudo usermod -a -G docker ec2-user
# Reboot instance
sudo systemctl enable docker
```

#### Install Minikube
```bash
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
minikube start --cpus=6 --memory=8192 --disk-size=40g
```

