output "alb_id" {
  description = "Application Load Balancer ID."
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "Application Load Balancer ARN."
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "Target group ARN."
  value       = aws_lb_target_group.app.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer."
  value       = aws_lb.main.arn_suffix
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the target group."
  value       = aws_lb_target_group.app.arn_suffix
}
