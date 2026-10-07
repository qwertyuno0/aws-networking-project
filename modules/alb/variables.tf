variable "project_name" {
  description = "project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "environment name"
  type        = string
}

variable "vpc_id" {
  description = "vpc id for alb creation"
  type        = string
}

variable "public_subnet_ids" {
  description = "public subnet id for alb"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "security grp id for alb"
  type        = string
}


