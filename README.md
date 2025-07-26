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

#### Install Kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

#### Install Helm
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

#### Install K9s (Optional)
```bash
curl -sS https://webinstall.dev/k9s | bash
```

### 3. External Secrets Operator Setup

#### Install ESO
```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets \
   external-secrets/external-secrets \
    -n external-secrets \
    --create-namespace \
    --set installCRDs=true
```

#### Create AWS Credentials Secret
```bash
kubectl create secret generic aws-airbyte-credentials \
  --from-literal=access_key=YOUR_ACCESS_KEY \
  --from-literal=secret_access_key=YOUR_SECRET_KEY
```

#### Apply SecretStore Configuration
```yaml
# secrets_store.yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: airbyte-secret-store
spec:
  provider: 
    aws:
      service: SecretsManager
      region: eu-central-1 
      auth:
        secretRef:
          accessKeyIDSecretRef:
            name: aws-airbyte-credentials
            key: access_key
          secretAccessKeySecretRef: 
            name: aws-airbyte-credentials
            key: secret_access_key
```

```bash
kubectl apply -f secrets_store.yaml
```

#### Apply ExternalSecret Configuration
```yaml
# external_secrets.yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: airbyte-external-secret
spec:
  refreshInterval: 1m
  secretStoreRef:
    name: airbyte-secret-store
    kind: SecretStore
  target:
    name: airbyte-config-secrets
    creationPolicy: Owner
  dataFrom:
  - extract:
      key: airbyte_eso
```

```bash
kubectl apply -f external_secrets.yaml
```

### 4. Airbyte Deployment

#### Add Airbyte Helm Repository
```bash
helm repo add airbyte https://airbytehq.github.io/helm-charts
helm repo update
```

#