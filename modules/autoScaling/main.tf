
#--------------
# latest ubuntu ami
# ------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#------------------
# launch template
#------------------

resource "aws_launch_template" "app" {
  name_prefix = "${var.environment}-autoscaling-"

  image_id = data.aws_ami.ubuntu.id

  instance_type = "t3.micro"

  key_name = var.key_name

  #-------------------
  #iam instance profile
  #-------------------

  iam_instance_profile {
    name = var.instance_profile_name
  }

  #-----------------------
  #security group
  #-----------------------

  vpc_security_group_ids = [
    var.private_ec2_sg_id
  ]

  #-----------------------
  # user data 
  # ----------------------

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    repo_ip     = var.package_repo_ip
    environment = var.environment
  }))

  # -----------------------------------
  # EC2 Instance Tags
  # -----------------------------------

  tag_specifications {

    resource_type = "instance"

    tags = {

      Name = "${var.environment}-autoscaling-instance"

      Environment = var.environment

      ManagedBy = "Terraform"

      Project = "aws-networking-project"

    }
  }


  # -----------------------------------
  # Launch Template Tags
  # -----------------------------------

  tags = {

    Name = "${var.environment}-autoscaling-launch-template"

    Environment = var.environment

    ManagedBy = "Terraform"

    Project = "aws-networking-project"

  }

}


# -----------------------------------
# Auto Scaling Group
# -----------------------------------

resource "aws_autoscaling_group" "app" {

  name = "${var.environment}-private-ec2-asg"

  # -----------------------------------
  # Capacity
  # -----------------------------------

  min_size = var.min_size

  desired_capacity = var.desired_capacity

  max_size = var.max_size


  # -----------------------------------
  # Private Subnets
  # -----------------------------------

  vpc_zone_identifier = var.private_subnet_ids


  # -----------------------------------
  # Health Check
  # -----------------------------------

  health_check_type = "ELB"

  health_check_grace_period = 600


  # -----------------------------------
  # Launch Template
  # -----------------------------------

  launch_template {

    id = aws_launch_template.app.id

    version = "$Latest"

  }


  # -----------------------------------
  # Tags
  # -----------------------------------

  tag {

    key = "Name"

    value = "${var.environment}-autoscaling-instance"

    propagate_at_launch = true

  }

  tag {

    key = "Environment"

    value = var.environment

    propagate_at_launch = true

  }

  tag {

    key = "ManagedBy"

    value = "Terraform"

    propagate_at_launch = true

  }

  tag {

    key = "Project"

    value = "aws-networking-project"

    propagate_at_launch = true

  }


  # -----------------------------------
  # Lifecycle
  # -----------------------------------

  lifecycle {

    create_before_destroy = true

  }

}

# -----------------------------------
# Attach Auto Scaling Group to ALB
# Target Group
# -----------------------------------

resource "aws_autoscaling_attachment" "app" {

  autoscaling_group_name = aws_autoscaling_group.app.name

  lb_target_group_arn = var.target_group_arn
}
