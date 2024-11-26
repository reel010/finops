# provider "aws" {
#   region = "us-east-1"
#   profile = "default"
# }

# resource "aws_instance" "example" {
#   ami           = "ami-0453ec754f44f9a4a"  # Amazon Linux 2 AMI
#   instance_type = "t2.micro"
#   count         = 2  # To create two instances

#   tags = {
#     Name = "CheapInstance"
#   }
# }