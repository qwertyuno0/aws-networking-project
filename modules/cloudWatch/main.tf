#-------------------
#ec2 / asg -> high cpu
#-------------------

resource "aws_cloudwatch_metric_alarm" "asg_high_cpu" {
  alarm_name          = "${var.environment}-asg-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 30


  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }
  alarm_description = "Alarm when ASG EC2 CPU utilization is high"

  alarm_actions = [var.sns_topic_arn]

  treat_missing_data = "notBreaching"

}


#--------------------
#alb -> unhealthy targets
#--------------------

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets" {
  alarm_name          = "${var.environment}-alb-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_description = "Alarm when ALB has unhealthy targets"

  alarm_actions      = [var.sns_topic_arn]
  treat_missing_data = "notBreaching"
}


#------------------
#alb -> request count
#--------------------

resource "aws_cloudwatch_metric_alarm" "alb_request_count" {
  alarm_name          = "${var.environment}-alb-request-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_description = "Alarm when ALB request count is high"

  alarm_actions = [var.sns_topic_arn]

  treat_missing_data = "notBreaching"
}

#-----------------
#alb -> target response time
# -----------------

resource "aws_cloudwatch_metric_alarm" "alb_high_response_time" {
  alarm_name          = "${var.environment}-alb-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "alarm when alb target response time is high"
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
  treat_missing_data = "notBreaching"
}

#---------------------
#alb -> http 5** Errors
#-----------------------

resource "aws_cloudwatch_metric_alarm" "alb_http_5xx" {
  alarm_name          = "${var.environment}-alb-http-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "alarm when alb generates http 5** errors"
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
  treat_missing_data = "notBreaching"
}



