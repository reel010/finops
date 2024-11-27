provider "aws" {
  region = "us-east-1"
  profile = "default"
}

# Security Group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  name_prefix = "ec2_security_group"
  description = "Allow all inbound and outbound traffic"
  
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Launch 10 t3.micro EC2 instances
resource "aws_instance" "t3_micro_instance" {
  count         = 1
  ami           = "ami-0166fe664262f664c"  # Replace with the latest Amazon Linux 2 AMI in your region
  instance_type = "t2.small"
  key_name      = "try"  # Replace with your actual EC2 key pair name
  security_groups = [aws_security_group.ec2_sg.name]
  tags = {
    Name = "TestInstance-${count.index + 1}"
  }
}

# Optionally, Output instance IDs
output "instance_ids" {
  value = aws_instance.t3_micro_instance[*].id
}

