variable "environment" {
  description = "Environment name"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where Auto Scaling instances will run"
  type        = list(string)
}

variable "private_ec2_sg_id" {
  description = "Private EC2 Security Group ID"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "package_repo_ip" {
  description = "Private IP address of the Bastion package repository"
  type        = string
}

variable "min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 4
}

variable "target_group_arn" {
  description = "arn of the alb target group"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for ASG lifecycle notifications"
  type        = string
}

