data "aws_ami" "ubuntu" {

  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }


  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


#---------------------
# bastion host ec2
# ---------------------

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = var.public_subnet_id

  vpc_security_group_ids = [
    var.bastion_sg_id
  ]

  key_name = var.key_name

  iam_instance_profile = var.instance_profile_name

  associate_public_ip_address = true

  user_data = <<-EOF
  #!/bin/bash

  set -e

  # Update package lists
  apt-get update -y

  # Install Nginx and repository tools
  apt-get install -y nginx dpkg-dev

  # Create package repository directory
  mkdir -p /var/www/html/repo

  # Download Apache and all required packages
  apt-get --download-only install -y apache2

  # Copy downloaded .deb packages to the repository
  cp /var/cache/apt/archives/*.deb /var/www/html/repo/

   # Generate APT package index
   cd /var/www/html/repo
   dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz

   # Start Nginx
   systemctl enable nginx
   systemctl restart nginx

   EOF



  tags = {
    Name = "${var.environment}-bastion"
  }
}

# ----------------
# elastic ip for bastion
# ----------------

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"
  tags = {
    Name = "${var.environment}-bastion-eip"
  }
}

