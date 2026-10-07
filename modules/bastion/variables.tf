variable "public_subnet_id" {
  description = "public subent where bastion host launched"
  type        = string
}

variable "bastion_sg_id" {
  description = "sg id for bastion host"
  type        = string
}

variable "instance_profile_name" {
  description = "iam instance profile for ec2"
  type        = string
}

variable "key_name" {
  description = " aws ec2 pair name "
  type        = string
}

variable "environment" {
  description = "environment name"
  type        = string
}

