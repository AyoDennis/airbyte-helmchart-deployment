# Production-grade Airbyte Deployment on Kubernetes

A comprehensive guide for deploying Airbyte on AWS using Kubernetes (Minikube), Terraform, and externalized storage for a production-ready, highly available, and cost-efficient setup.

## Overview

This project demonstrates how to move from a basic Docker-Compose Airbyte deployment to a robust Kubernetes environment with external database storage, advanced security, and production-grade logging.

> **Note**: This setup uses Minikube for demonstration purposes. For actual production deployments, consider using Amazon EKS or other managed Kubernetes services.

## Architecture Components
<img width="1239" height="614" alt="Airbyte Architecture" src="https://github.com/user-attachments/assets/3699b4b9-7174-4e2c-a92c-bab4abbda798" />

[Airbyte Deployment Architecture](https://github.com/AyoDennis/airbyte-helmchart-deployment/blob/main/Airbyte%20Architecture.png?raw=true)
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

#### Pull and Configure Airbyte Chart
```bash
helm pull --untar airbyte/airbyte
cd airbyte
```

#### Update values.yaml
Configure external database and S3 storage in `values.yaml`:

```yaml
storage:
  type: "S3"
  storageSecretName: "airbyte-config-secrets"
  bucket:
    log: your-airbyte-project-bucket
    state: your-airbyte-project-bucket
    workloadOutput: your-airbyte-project-bucket
  s3:
    region: "eu-central-1"
    authenticationType: credentials

# Configure external database
postgresql:
  enabled: false

externalDatabase:
  host: "your-rds-endpoint"
  port: 5432
  database: "airbyte_db"
  existingSecret: "airbyte-config-secrets"
  existingSecretPasswordKey: "database-password"
  existingSecretUsernameKey: "database-user"
```

#### Deploy Airbyte
```bash
helm install prod . --timeout 10m
```

### 5. External Access Setup

#### Install Ngrok
```bash
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
sudo tar xvzf ./ngrok-v3-stable-linux-amd64.tgz -C /usr/local/bin
ngrok authtoken YOUR_NGROK_AUTHTOKEN
```

#### Port Forward and Tunnel
```bash
# Port forward Airbyte webapp
kubectl port-forward svc/prod-airbyte-webapp-svc 5000:80

# In another terminal, create ngrok tunnel
ngrok http 5000
```

## 🔍 Monitoring and Troubleshooting

### Check Pod Status
```bash
kubectl get pods
kubectl get services
```

### Monitor with K9s
```bash
k9s
```

### View Logs
```bash
kubectl logs -f deployment/prod-airbyte-server
```

### Database Connection
Connect to your RDS instance using a SQL client like DBeaver to monitor Airbyte metadata.

## Security Considerations

- **VPN Access**: All resources are accessible only through VPN
- **Private Database**: RDS instance is not publicly accessible
- **Secrets Management**: Credentials stored in AWS Secrets Manager
- **Least Privilege**: IAM policies follow principle of least privilege
- **Network Isolation**: Resources isolated within VPC

## Configuration Files

### Key Configuration Files Structure
```
├── airbyte/
│    └── charts
│    ├── templates
│    ├── tests
│    ├── .helmignore
│    ├── airbyte-pro-values.yaml
│    ├── Chart.lock
│    ├── Chart.yaml
│    ├── Chart.yaml.local
│    ├── Chart.yaml.test
│    ├── README.md
│    ├── values.yaml
│    ├── values.yaml.test
│   
├── infrastructure/
│   ├── provider.tf
│   ├── backend.tf
│   ├── main.tf
│   └── certificates/
│        ├── ca.crt
│        ├── server.crt
│        ├── server.key
│        ├── client1.domain.tld.crt
│        └── client1.domain.tld.key
│       
└── kubernetes/
    ├── secrets_store.yaml
    └── external_secrets.yaml
```

## Benefits

1. **Cost Efficiency**: Self-hosted solution reduces ELT costs
2. **High Availability**: External database and storage
3. **Security**: VPN access, secrets management, network isolation
4. **Scalability**: Kubernetes-based deployment
5. **Monitoring**: Comprehensive logging and monitoring setup

## More Production Considerations

- Replace Minikube with EKS or other managed Kubernetes service
- Implement proper backup strategies for RDS
- Set up monitoring and alerting (Prometheus, Grafana)
- Configure resource limits and requests
- Implement CI/CD pipeline for deployments
- Use private subnets for database and application tiers

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions and support, please open an issue in the repository or connect on LinkedIn.


**Note**: This setup is designed for demonstration and learning purposes. For production deployments, additional security hardening, monitoring, and high availability configurations should be implemented.
