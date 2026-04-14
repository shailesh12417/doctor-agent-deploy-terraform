terraform {
  required_version = ">= 1.0"
  
  # 1. REMOTE STATE STORAGE (Fixes "Already Exists" error)
  backend "s3" {
    bucket         = "shailesh-terraform-state-2026" # Matches the bucket you created
    key            = "fastapi/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-north-1"
}

# 2. DATA SOURCE FOR AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# 3. SECURITY GROUP
resource "aws_security_group" "app_sg" {
  name        = "doctor-agent-sg-final" # New name to start fresh
  description = "Allow SSH and FastAPI"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
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

# 4. EC2 INSTANCE
resource "aws_instance" "app_server1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = "terraform" # Ensure this exists in Stockholm Console
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y python3-pip python3-venv git
              EOF

  tags = {
    Name = "DoctorAgentServer"
  }
}

output "instance_public_ip" {
  value = aws_instance.app_server1.public_ip
}
