module "vpc" {
  source = "./modules/vpc"

  vpc_name             = var.vpc_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  environment          = var.environment
}

data "aws_caller_identity" "current" {}

locals {
  s3_bucket_name = var.s3_bucket_name != "" ? var.s3_bucket_name : replace(lower("${var.vpc_name}-${var.environment}-${data.aws_caller_identity.current.account_id}-${var.aws_region}-${terraform.workspace}"), "_", "-")
}

# ---------- SECURITY GROUP ----------
resource "aws_security_group" "web" {
  name        = "${var.vpc_name}-web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name        = "${var.vpc_name}-web-sg"
    Environment = var.environment
  }
}

# ---------- KEY PAIR ----------
# Only created when var.key_name is not provided
resource "tls_private_key" "web" {
  count     = var.key_name == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "web" {
  count      = var.key_name == "" ? 1 : 0
  key_name   = "${var.vpc_name}-web-key-${terraform.workspace}"
  public_key = tls_private_key.web[0].public_key_openssh
}

# ---------- AMI DATA SOURCE ----------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ---------- EC2 INSTANCE ----------
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_name != "" ? var.key_name : aws_key_pair.web[0].key_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    echo "<h1>Hello from ${var.environment} - $(hostname)</h1>" > /var/www/html/index.html
    systemctl start httpd
    systemctl enable httpd
  EOF

  tags = {
    Name        = "${var.vpc_name}-web-${var.environment}"
    Environment = var.environment
  }
}

# ---------- S3 BUCKET ----------
resource "aws_s3_bucket" "this" {
  count         = var.create_s3_bucket ? 1 : 0
  bucket        = local.s3_bucket_name
  force_destroy = var.s3_force_destroy

  tags = {
    Name        = local.s3_bucket_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
