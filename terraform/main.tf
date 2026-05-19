terraform {

  required_version = ">= 1.0"

  required_providers {

    aws = {

      source  = "hashicorp/aws"

      version = "~> 5.0"

    }

  }

}

provider "aws" {

  region = var.aws_region

}

# ============================================

# NETWORKING

# ============================================

data "aws_vpc" "default" {

  default = true

}

data "aws_subnet" "default_az1" {

  filter {

    name   = "vpc-id"

    values = [data.aws_vpc.default.id]

  }

  filter {

    name   = "availability-zone"

    values = [data.aws_availability_zones.available.names[0]]

  }

  filter {

    name   = "default-for-az"

    values = ["true"]

  }

}

data "aws_subnet" "default_az2" {

  filter {

    name   = "vpc-id"

    values = [data.aws_vpc.default.id]

  }

  filter {

    name   = "availability-zone"

    values = [data.aws_availability_zones.available.names[1]]

  }

  filter {

    name   = "default-for-az"

    values = ["true"]

  }

}

# ============================================

# SECURITY GROUPS

# ============================================

# ALB Security Group

resource "aws_security_group" "alb" {

  name_prefix = "ecommerce-prod-alb-sg-"

  description = "Security group for ALB"

  vpc_id      = data.aws_vpc.default.id

  ingress {

    from_port   = 80

    to_port     = 80

    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {

    from_port   = 443

    to_port     = 443

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

    Name = "alb-sg"

  }

}

# EC2 Security Group

resource "aws_security_group" "ec2" {

  name_prefix = "ecommerce-prod-ec2-sg-"

  description = "Security group for EC2 instances"

  vpc_id      = data.aws_vpc.default.id

  # SSH

  ingress {

    from_port   = 22

    to_port     = 22

    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }

  # HTTP from ALB

  ingress {

    from_port       = 80

    to_port         = 80

    protocol        = "tcp"

    security_groups = [aws_security_group.alb.id]

  }

  # HTTP direct access (demo only)

  ingress {

    from_port   = 80

    to_port     = 80

    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }

  # Node.js App (default PM2 port)

  ingress {

    from_port       = 3000

    to_port         = 3000

    protocol        = "tcp"

    security_groups = [aws_security_group.alb.id]

  }

  # MongoDB (internal)

  ingress {

    from_port   = 27017

    to_port     = 27017

    protocol    = "tcp"

    cidr_blocks = [data.aws_vpc.default.cidr_block]

  }

  egress {

    from_port   = 0

    to_port     = 0

    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {

    Name = "ec2-sg"

  }

}

# ============================================

# EC2 INSTANCES

# ============================================

resource "aws_instance" "web1" {

  ami                    = data.aws_ami.ubuntu.id

  instance_type          = var.instance_type

  key_name               = var.key_name

  subnet_id              = data.aws_subnet.default_az1.id

  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = file("${path.module}/user_data.sh")

  tags = {

    Name = "web-instance-1"

    Role = "web"

  }

}

resource "aws_instance" "web2" {

  ami                    = data.aws_ami.ubuntu.id

  instance_type          = var.instance_type

  key_name               = var.key_name

  subnet_id              = data.aws_subnet.default_az2.id

  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = file("${path.module}/user_data.sh")

  tags = {

    Name = "web-instance-2"

    Role = "web"

  }

}

# ============================================

# ALB (Application Load Balancer)

# ============================================

resource "aws_lb" "main" {

  # AWS requires short name_prefix (max 6 chars). Use compact prefix to avoid errors.

  name_prefix        = "ecalb-"

  internal           = false

  load_balancer_type = "application"

  security_groups    = [aws_security_group.alb.id]

  subnets            = [data.aws_subnet.default_az1.id, data.aws_subnet.default_az2.id]

  enable_deletion_protection = false

  tags = {

    Name = "ecommerce-prod-alb"

  }

}

# Target Group

resource "aws_lb_target_group" "web" {

  # short prefix (<=6 chars) to satisfy provider validation

  name_prefix = "ectg-"

  port        = 80

  protocol    = "HTTP"

  vpc_id      = data.aws_vpc.default.id

  target_type = "instance"

  health_check {

    healthy_threshold   = 2

    unhealthy_threshold = 2

    timeout             = 3

    interval            = 30

    path                = "/"

    matcher             = "200"

  }

  tags = {

    Name = "web-tg"

  }

}

# Register targets

resource "aws_lb_target_group_attachment" "web1" {

  target_group_arn = aws_lb_target_group.web.arn

  target_id        = aws_instance.web1.id

  port             = 80

}

resource "aws_lb_target_group_attachment" "web2" {

  target_group_arn = aws_lb_target_group.web.arn

  target_id        = aws_instance.web2.id

  port             = 80

}

# ALB Listener

resource "aws_lb_listener" "web" {

  load_balancer_arn = aws_lb.main.arn

  port              = "80"

  protocol          = "HTTP"

  default_action {

    type             = "forward"

    target_group_arn = aws_lb_target_group.web.arn

  }

}

# ============================================

# IAM ROLE FOR EC2

# ================ (Disabled for AWS Academy)

# ============================================

# AWS Academy learner labs have restricted IAM permissions

# Role creation is handled outside this Terraform configuration

# ============================================

# DATA SOURCES

# ============================================

data "aws_availability_zones" "available" {

  state = "available"

}

data "aws_ami" "ubuntu" {

  most_recent = true

  owners      = ["099720109477"]

  filter {

    name   = "name"

    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]

  }

  filter {

    name   = "virtualization-type"

    values = ["hvm"]

  }

}