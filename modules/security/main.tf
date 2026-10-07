resource "aws_security_group" "bastion" {

  name        = "bastion-sg"
  description = "security group for bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "ssh from my laptop"

    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [var.my_ip]
  }
  ingress {
    description = "HTTP from VPC for package repository"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "bastion-sg"

  }
}


# application lb security group 



resource "aws_security_group" "alb" {


  name        = "alb-sg"
  description = "security group for alb"
  vpc_id      = var.vpc_id

  # http from anywhere
  ingress {
    description = "http for internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }






  egress {

    description = "allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }

}


# private ec2 security group

resource "aws_security_group" "private-ec2" {


  name        = "private-ec2-sg"
  description = " sg for private app server"
  vpc_id      = var.vpc_id

  # http traffic only alb sg

  ingress {
    description = "http from alb"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    security_groups = [aws_security_group.alb.id]
  }

  # ssh only from bastion sg

  ingress {
    description     = "ssh from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "allow all outbound traffic"

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}
# --------------------

# public network acl 

# --------------------

resource "aws_network_acl" "public" {
  vpc_id = var.vpc_id

  subnet_ids = var.public_subnet_ids

  tags = {
    Name = "public_nacl"
  }
}

# allow http 

resource "aws_network_acl_rule" "public_http_in" {
  network_acl_id = aws_network_acl.public.id

  rule_number = 100
  egress      = false

  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = "0.0.0.0/0"

  from_port = 80
  to_port   = 80
}

# Allow HTTPS
resource "aws_network_acl_rule" "public_https_in" {
  network_acl_id = aws_network_acl.public.id

  rule_number = 110
  egress      = false

  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = "0.0.0.0/0"

  from_port = 443
  to_port   = 443
}

# Allow ssh
resource "aws_network_acl_rule" "public_ssh_in" {
  network_acl_id = aws_network_acl.public.id

  rule_number = 120
  egress      = false

  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = var.my_ip

  from_port = 22
  to_port   = 22
}
resource "aws_network_acl_rule" "public_ssh_out" {
  network_acl_id = aws_network_acl.public.id

  rule_number = 130
  egress      = true
  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = var.vpc_cidr

  from_port = 22
  to_port   = 22
}





# Allow ephemeral ports (return traffic)
resource "aws_network_acl_rule" "public_ephemeral_in" {
  network_acl_id = aws_network_acl.public.id

  rule_number = 130
  egress      = false

  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = "0.0.0.0/0"

  from_port = 1024
  to_port   = 65535
}

# Allow HTTP out
resource "aws_network_acl_rule" "public_http_out" {
  network_acl_id = aws_network_acl.public.id

  rule_number = 100
  egress      = true

  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = "0.0.0.0/0"

  from_port = 80
  to_port   = 80
}




# Allow ephemeral out
resource "aws_network_acl_rule" "public_ephemeral_out" {
  network_acl_id = aws_network_acl.public.id

  rule_number = 120
  egress      = true

  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = "0.0.0.0/0"

  from_port = 1024
  to_port   = 65535
}

# ----------------------

# private network acl

# ----------------------


resource "aws_network_acl" "private" {
  vpc_id = var.vpc_id

  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "private_nacl"
  }
}

# HTTP from VPC
resource "aws_network_acl_rule" "private_http_in" {
  network_acl_id = aws_network_acl.private.id

  rule_number = 100
  egress      = false

  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = var.vpc_cidr

  from_port = 80
  to_port   = 80
}

# SSH from VPC
resource "aws_network_acl_rule" "private_ssh_in" {
  network_acl_id = aws_network_acl.private.id

  rule_number = 110
  egress      = false

  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = var.vpc_cidr

  from_port = 22
  to_port   = 22
}

# Ephemeral Ports
resource "aws_network_acl_rule" "private_ephemeral_in" {
  network_acl_id = aws_network_acl.private.id

  rule_number = 120
  egress      = false

  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = var.vpc_cidr

  from_port = 1024
  to_port   = 65535
}

# private nacl outbound rule 


# HTTP out 
resource "aws_network_acl_rule" "private_http_out" {
  network_acl_id = aws_network_acl.private.id

  rule_number = 100
  egress      = true

  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = var.vpc_cidr

  from_port = 80
  to_port   = 80
}


# Ephemeral Ports out
resource "aws_network_acl_rule" "private_ephemeral_out" {
  network_acl_id = aws_network_acl.private.id

  rule_number = 120
  egress      = true

  protocol    = "tcp"
  rule_action = "allow"

  cidr_block = var.vpc_cidr

  from_port = 1024
  to_port   = 65535
}




# ----------------
