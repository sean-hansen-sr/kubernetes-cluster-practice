provider "aws" {
  region = "us-east-1"
}

# 1. Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "private-vpc"
  }
}

# 2. Create a Private Subnet (No Internet Gateway)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet"
  }
}

# 3. Create a Security Group
resource "aws_security_group" "private_sg" {
  name        = "private-ubuntu-sg"
  description = "Allow internal traffic"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-ubuntu-sg"
  }
}

# 4. Get Latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# 5. Deploy 3 Ubuntu VMs with No External IP
resource "aws_instance" "ubuntu_vm" {
  count                  = 3
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  # This explicitly prevents assigning a public/external IP address
  associate_public_ip_address = false

  tags = {
    Name = "ubuntu-private-${count.index + 1}"
  }
}
