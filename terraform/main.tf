terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_security_group" "app" {
  name        = "backend-sg"
  description = "SSH y app"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.jenkins.key_name
  vpc_security_group_ids = [aws_security_group.app.id]
  user_data              = file("${path.module}/cloud-init.yaml")

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "backend-server"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}
resource "aws_s3_bucket" "backup" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "backup" {
  bucket                  = aws_s3_bucket.backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "carpeta_database" {
  bucket  = aws_s3_bucket.backup.id
  key     = "${var.apellido}/database/"
  content = ""
}

resource "aws_s3_object" "carpeta_database_jenkins" {
  bucket  = aws_s3_bucket.backup.id
  key     = "${var.apellido}/database-jenkins/"
  content = ""
}

resource "aws_key_pair" "jenkins" {
  key_name   = "jenkins-key"
  public_key = file(var.ssh_public_key_path)

  lifecycle {
    ignore_changes = [public_key]
  }
}