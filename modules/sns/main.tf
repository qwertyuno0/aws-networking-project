#----------------
#sns topic 
#----------------

resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-alerts"
}

#-----------------------
#email subscription
#-----------------------

resource "aws_sns_topic_subscription" "subscription" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
