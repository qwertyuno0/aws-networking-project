variable "aws_region" {
  default = "ap-south-1"
}


variable "key_name" {
  description = "aws ec2 key pair name "
  type        = string
}

variable "alert_email" {
  description = "Email address for SNS alert notifications"
  type        = string
  sensitive   = true
}
