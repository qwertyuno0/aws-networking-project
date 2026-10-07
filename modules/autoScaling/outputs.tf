output "launch_template_id" {
  description = "ID of the Auto Scaling Launch Template"
  value       = aws_launch_template.app.id
}

output "launch_template_name" {
  description = "Name of the Auto Scaling Launch Template"
  value       = aws_launch_template.app.name
}

output "autoscaling_group_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.arn
}

output "min_size" {
  description = "Minimum ASG size"
  value       = aws_autoscaling_group.app.min_size
}

output "desired_capacity" {
  description = "Desired ASG capacity"
  value       = aws_autoscaling_group.app.desired_capacity
}

output "max_size" {
  description = "Maximum ASG size"
  value       = aws_autoscaling_group.app.max_size
}
