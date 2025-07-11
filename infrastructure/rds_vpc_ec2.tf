# Create VPC named "rds_vpc"
resource "aws_vpc" "rds_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "rds_vpc"
    Environment = "Production"
  }
}

# Create public subnet
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.rds_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_1"
    Environment = "Production"
  }
}

# Create private subnet
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.rds_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_2"
    Environment = "Production"
  }
}


# Create Internet Gateway for public access
resource "aws_internet_gateway" "rds_igw" {
  vpc_id = aws_vpc.rds_vpc.id

  tags = {
    Name = "rds_igw"
  }
}

# Route Table for public subnets 
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.rds_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rds_igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}


# Associate the public subnet with the public route table
resource "aws_route_table_association" "public_subnet_association1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "public_subnet_association2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_public_subnet_group"
  subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "subnet_group"
  }
}


resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow access"
  vpc_id      = aws_vpc.rds_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_sg"
  }
}



resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 20
  identifier           = "airbyte-db"
  db_name              = "airbyte"
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.micro"
  username             = "airadmin"
  password             = "password2025"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = true 
  skip_final_snapshot  = true

}


data "aws_key_pair" "key_pair" {
  key_name           = "deji-eu-keypair"
  include_public_key = true

}


resource "aws_ebs_volume" "ebs_volume" {
  availability_zone = "eu-central-1a"
  size              = 40
  type              = gp3

}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/dpe"
  volume_id   = aws_ebs_volume.ebs_volume.id
  instance_id = aws_instance.ec2_instance.id
}


resource "aws_instance" "ec2_instance" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t2.2xlarge"
  subnet_id     = aws_subnet.public_subnet_1.id
  key_name = data.aws_key_pair.key_pair.key_name


  tags = {
    Name = "airbyte-server"
  }
}

