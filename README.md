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

