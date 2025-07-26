# # Create VPC named "airbyte_vpc"
# resource "aws_vpc" "airbyte_vpc" {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_support   = true
#   enable_dns_hostnames = true

#   tags = {
#     Name = "airbyte_vpc"
#     Environment = "Production"
#   }
# }

# # Create public subnet 1
# resource "aws_subnet" "public_subnet_1" {
#   vpc_id                  = aws_vpc.airbyte_vpc.id
#   cidr_block              = "10.0.1.0/24"
#   availability_zone       = "eu-central-1a"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "public_subnet_1"
#     Environment = "Production"
#   }
# }

# # Create public subnet 2
# resource "aws_subnet" "public_subnet_2" {
#   vpc_id                  = aws_vpc.airbyte_vpc.id
#   cidr_block              = "10.0.2.0/24"
#   availability_zone       = "eu-central-1b"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "public_subnet_2"
#     Environment = "Production"
#   }
# }

# # Create Internet Gateway for public access
# resource "aws_internet_gateway" "airbyte_igw" {
#   vpc_id = aws_vpc.airbyte_vpc.id

#   tags = {
#     Name = "airbyte_igw"
#   }
# }

# # Route Table for public subnets
# resource "aws_route_table" "public_route_table" {
#   vpc_id = aws_vpc.airbyte_vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.airbyte_igw.id
#   }

#   tags = {
#     Name = "public_route_table"
#   }
# }

# # Associate the public subnet with the public route table
# resource "aws_route_table_association" "public_subnet_association1" {
#   subnet_id      = aws_subnet.public_subnet_1.id
#   route_table_id = aws_route_table.public_route_table.id
# }

# # Associate the public subnet with the public route table
# resource "aws_route_table_association" "public_subnet_association2" {
#   subnet_id      = aws_subnet.public_subnet_2.id
#   route_table_id = aws_route_table.public_route_table.id
# }


# # AWS CLIENT VPN RESOURCES
# # AWS Account Certificate Manager

# resource "aws_acm_certificate" "client_certificate" {
#   private_key       = file("certificates/client1.domain.tld.key")
#   certificate_body  = file("certificates/client1.domain.tld.crt")
#   certificate_chain = file("certificates/ca.crt")

#   tags = {
#     Name = "client-cert"
#     }
# }

# # Import client certificate for VPN authentication
# # This certificate is used to authenticate VPN servers
# resource "aws_acm_certificate" "server_certificate" {
#   private_key       = file("certificates/server.key")
#   certificate_body  = file("certificates/server.crt")
#   certificate_chain = file("certificates/ca.crt")

#   tags =  {
#     Name = "server-cert"
#     }
# }

# # VPN Endpoint
# resource "aws_ec2_client_vpn_endpoint" "airbyte_vpn_endpoint" {
#   description            = "terraform-clientvpn-endpoint"
#   server_certificate_arn = aws_acm_certificate.server_certificate.arn
#   client_cidr_block      = "172.16.0.0/22"
#   split_tunnel           = true   
#   vpc_id                 = aws_vpc.airbyte_vpc.id
#   transport_protocol     = "udp"
#   vpn_port               = 443
#   dns_servers            = ["8.8.8.8"]
#   security_group_ids = [aws_security_group.vpn_security_group.id]

#   client_login_banner_options {
#     banner_text = "Welcome, Dear Data Platform Hero!"
#     enabled     = true
#   }

#   authentication_options {
#     type                       = "certificate-authentication"
#     root_certificate_chain_arn = aws_acm_certificate.client_certificate.arn
#   }

#   connection_log_options {
#     enabled               = false
#   }
#   tags =  {
#     Name = "Terraformed VPN Stack"
#     }
# }

# # VPN Security group
# resource "aws_security_group" "vpn_security_group" {
#   name        = "allow_vpn_ssh_access" # Renamed for clarity
#   description = "Allow SSH from VPN clients and all outbound traffic"
#   vpc_id      = aws_vpc.airbyte_vpc.id

#   tags = {
#     Name = "allow_vpn_ssh"
#   }
# }


# resource "aws_vpc_security_group_egress_rule" "permit_all_traffic_ipv4" {
#   security_group_id = aws_security_group.vpn_security_group.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }


# # Add this authorization rule for your current setup (RDS in public subnets)
# resource "aws_ec2_client_vpn_authorization_rule" "airbyte_vpn_auth_public_subnet_1" {
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.airbyte_vpn_endpoint.id
#   target_network_cidr    = aws_subnet.public_subnet_1.cidr_block
#   authorize_all_groups   = true
# }

# resource "aws_ec2_client_vpn_authorization_rule" "airbyte_vpn_auth_public_subnet_2" {
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.airbyte_vpn_endpoint.id
#   target_network_cidr    = aws_subnet.public_subnet_2.cidr_block
#   authorize_all_groups   = true
# }


# # Client VPN Network Association (associate subnets where VPN ENIs will be created)
# # For subnet 1
# resource "aws_ec2_client_vpn_network_association" "airbyte_vpn_association_1" {
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.airbyte_vpn_endpoint.id
#   subnet_id              = aws_subnet.public_subnet_1.id
# }

# # For subnet 2
# resource "aws_ec2_client_vpn_network_association" "airbyte_vpn_association_2" {
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.airbyte_vpn_endpoint.id
#   subnet_id              = aws_subnet.public_subnet_2.id
# }


# # Client VPN Authorization Rule (allows clients to access your VPC CIDR)
# resource "aws_ec2_client_vpn_authorization_rule" "airbyte_vpn_auth_vpc" {
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.airbyte_vpn_endpoint.id
#   target_network_cidr    = aws_vpc.airbyte_vpc.cidr_block # Allow access to your VPC
#   authorize_all_groups   = true
# }


# # ===========
# # EC2 Security group
# resource "aws_security_group" "ec2_security_group" {
#   name        = "allow_ssh_for_vpn"
#   description = "Allow SSH from VPN clients and all outbound traffic"
#   vpc_id      = aws_vpc.airbyte_vpc.id

#   tags = {
#     Name = "allow_ssh_for_vpn"
#   }
# }


# # Allow SSH from VPC CIDR as well (for troubleshooting)
# resource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_vpc" {
#   security_group_id = aws_security_group.ec2_security_group.id
#   cidr_ipv4         = aws_vpc.airbyte_vpc.cidr_block
#   from_port         = 22
#   ip_protocol       = "tcp"
#   to_port           = 22
# }

# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
#   security_group_id = aws_security_group.ec2_security_group.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }

# # Database security group - Use private subnets for RDS in a real-world scenario

# resource "aws_db_subnet_group" "db_subnet_group" {
#   name       = "db_subnet_group" # Renamed to be more general
#   subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id] # Still public, but not ideal for DB

#   tags = {
#     Name = "subnet_group"
#   }
# }

# # RDS security group
# resource "aws_security_group" "rds_sg" {
#   name        = "rds-sg-vpn-access" # Renamed for clarity
#   description = "Allow PostgreSQL access from VPN clients"
#   vpc_id      = aws_vpc.airbyte_vpc.id

#   ingress {
#     from_port   = 5432
#     to_port     = 5432
#     protocol    = "tcp"
#     # Allow RDS access ONLY from the Client VPC's assigned CIDR block
#     cidr_blocks = [aws_vpc.airbyte_vpc.cidr_block]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "rds_sg"
#   }
# }

# # Secrets credentials (Assuming these are properly configured outside this TF)
# data "aws_secretsmanager_secret" "eso_secret" {
#   name = "airbyte_eso"
# }

# # To retrieve the secret's value
# data "aws_secretsmanager_secret_version" "eso_secret" {
#   secret_id = data.aws_secretsmanager_secret.eso_secret.id
# }

# # Parsing the secret, so it's available locally (assuming it's JSON formatted)
# locals {
#   db_credentials = jsondecode(data.aws_secretsmanager_secret_version.eso_secret.secret_string)
# }

# # RDS Postgres instance
# resource "aws_db_instance" "rds_instance" {
#   allocated_storage    = 20
#   identifier           = "airbyte-db"
#   db_name              = local.db_credentials.database
#   engine               = "postgres"
#   engine_version       = "15"
#   instance_class       = "db.t3.micro"
#   username             = local.db_credentials.database-user 
#   password             = local.db_credentials.database-password
#   db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
#   vpc_security_group_ids = [aws_security_group.rds_sg.id]
#   publicly_accessible    = false 
#   skip_final_snapshot  = true

# }

# # EC2 Key Pair (assuming this exists)
# data "aws_key_pair" "key_pair" {
#   key_name           = "deji-eu-keypair"
#   include_public_key = true
# }

# # EC2 Instance.
# resource "aws_instance" "ec2_instance" {
#   ami           = "ami-0229b8f55e5178b65" 
#   instance_type = "t2.2xlarge" 
#   subnet_id     = aws_subnet.public_subnet_1.id 
#   key_name      = data.aws_key_pair.key_pair.key_name
#   vpc_security_group_ids = [aws_security_group.ec2_security_group.id]

#  root_block_device {
#     volume_size = 60
#     volume_type = "gp3"
#   }

#   tags = {
#     Name = "airbyte-server"
#   }
# }

