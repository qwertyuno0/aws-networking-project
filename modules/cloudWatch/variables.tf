variable "environment" {
  description = "env name "
  type        = string
}

variable "autoscaling_group_name" {
  description = "name of the asg"
  type        = string
}



variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications"
  type        = string
}
