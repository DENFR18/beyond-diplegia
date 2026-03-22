locals {
  name = "beyond-diplegia-${var.env}"
  tags = {
    project     = "beyond-diplegia"
    environment = var.env
    managed_by  = "terraform"
  }
}

# ─── AMI Ubuntu 22.04 ─────────────────────────────────────────────────────────

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ─── VPC ──────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "vpc-${local.name}" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.tags, { Name = "igw-${local.name}" })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = false
  tags                    = merge(local.tags, { Name = "snet-public-${local.name}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(local.tags, { Name = "rt-public-${local.name}" })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ─── Security Group ───────────────────────────────────────────────────────────

resource "aws_security_group" "web" {
  name   = "sg-${local.name}"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #trivy:ignore:AVD-AWS-0107
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #trivy:ignore:AVD-AWS-0107
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #trivy:ignore:AVD-AWS-0107
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #trivy:ignore:AVD-AWS-0104
  }

  tags = merge(local.tags, { Name = "sg-${local.name}" })
}

# ─── Key Pair ─────────────────────────────────────────────────────────────────

resource "aws_key_pair" "deployer" {
  key_name   = "key-${local.name}"
  public_key = var.public_key
  tags       = local.tags
}

# ─── EC2 ──────────────────────────────────────────────────────────────────────

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.deployer.key_name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 10
    encrypted   = true
  }

  tags = merge(local.tags, { Name = "ec2-${local.name}" })
}

# ─── Elastic IP ───────────────────────────────────────────────────────────────

resource "aws_eip" "web" {
  instance = aws_instance.web.id
  domain   = "vpc"
  tags     = merge(local.tags, { Name = "eip-${local.name}" })
}
