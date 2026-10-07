


data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  vpc_cidr = "10.0.0.0/16"
}


module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr = local.vpc_cidr

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_subnet_cidrs = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}

module "security" {
  source = "../../modules/security"

  vpc_id   = module.vpc.vpc_id
  vpc_cidr = local.vpc_cidr

  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  my_ip = "${chomp(data.http.my_ip.response_body)}/32"
}

module "iam" {
  source = "../../modules/iam"

  project_name = "aws-networking-project"

}


# bastion module 

module "bastion" {
  source = "../../modules/bastion"

  environment = "dev"

  public_subnet_id = module.vpc.public_subnet_ids[0]
  bastion_sg_id    = module.security.bastion_sg_id

  instance_profile_name = module.iam.instance_profile_name

  key_name = var.key_name


}


# alb for private ec2 instance

module "alb" {
  source = "../../modules/alb"

  project_name = "aws-networking-project"
  environment  = "dev"

  vpc_id = module.vpc.vpc_id

  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.alb_sg_id



}

#-------------------
#private ec2 auto scaling group
#----------------------

module "autoScaling" {
  source = "../../modules/autoScaling"

  environment = "dev"

  private_subnet_ids = module.vpc.private_subnet_ids

  private_ec2_sg_id = module.security.private_ec2_sg_id

  instance_profile_name = module.iam.instance_profile_name

  key_name = var.key_name

  package_repo_ip = module.bastion.bastion_private_ip

  target_group_arn = module.alb.target_group_arn

  sns_topic_arn = module.sns.topic_arn

  min_size         = 2
  desired_capacity = 2
  max_size         = 4
}


# -------------------
# CloudWatch Monitoring
# -------------------

module "cloudWatch" {
  source = "../../modules/cloudWatch"

  environment = "dev"

  autoscaling_group_name = module.autoScaling.autoscaling_group_name

  target_group_arn = module.alb.target_group_arn

  alb_arn_suffix = module.alb.alb_arn_suffix

  target_group_arn_suffix = module.alb.target_group_arn_suffix

  sns_topic_arn = module.sns.topic_arn
}


#sns notification service

module "sns" {
  source      = "../../modules/sns"
  environment = "dev"
  alert_email = var.alert_email
}

