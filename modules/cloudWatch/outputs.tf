output "high_cpu_alarm_name" {
  description = "ASG high CPU alarm"
  value       = aws_cloudwatch_metric_alarm.asg_high_cpu.alarm_name
}

output "unhealthy_target_alarm_name" {
  description = "ALB unhealthy target alarm"
  value       = aws_cloudwatch_metric_alarm.alb_unhealthy_targets.alarm_name
}

output "request_count_alarm_name" {
  description = "ALB request count alarm"
  value       = aws_cloudwatch_metric_alarm.alb_request_count.alarm_name
}

output "response_time_alarm_name" {
  description = "ALB response time alarm"
  value       = aws_cloudwatch_metric_alarm.alb_high_response_time.alarm_name
}

output "http_5xx_alarm_name" {
  description = "ALB HTTP 5xx alarm"
  value       = aws_cloudwatch_metric_alarm.alb_http_5xx.alarm_name
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
