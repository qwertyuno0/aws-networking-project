#--------------------
#cloudwatch custom dashboard
#--------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      #--------------------
      #ec2 / asg -> cpu utilization
      #--------------------


      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title = "ASG -> EC2 CPU Utilization"
          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "AutoScalingGroupName",
              var.autoscaling_group_name
            ]
          ]
          period = 300
          stat   = "Average"
          region = "ap-south-1"
          view   = "timeSeries"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }

        }
      },

      #-------------------------
      #ASG -> DESIRED CAPACITY
      #------------------------

      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title = "Auto Scaling Group Capacity"

          metrics = [
            [
              "AWS/AutoScaling",
              "GroupDesiredCapacity",
              "AutoScalingGroupName",
              var.autoscaling_group_name
            ],
            [
              ".",
              "GroupInServiceInstances",
              ".",
              "."
            ]
          ]

          period = 300

          stat = "Average"

          region = "ap-south-1"

          view = "timeSeries"
        }
      },

      # ======================================================
      # ALB Request count
      # ======================================================

      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title = "ALB REQUEST COUNT"

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              var.alb_arn_suffix

            ]
          ]

          period = 60

          stat = "Sum"

          region = "ap-south-1"

          view = "timeSeries"
        }
      },

      # ======================================================
      # ALB target response time
      # ======================================================

      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title = "ALB -> target response time"

          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              var.alb_arn_suffix
            ]
          ]

          period = 60

          stat = "Average"

          region = "ap-south-1"

          view = "timeSeries"
        }
      },

      # ======================================================
      # ALB healthy / unhealthy targets
      # ======================================================

      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          title = "ALB TARGET HEALTH"

          metrics = [
            [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "TargetGroup",
              var.target_group_arn_suffix,
              "LoadBalancer",
              var.alb_arn_suffix
            ],
            [
              ".",
              "UnHealthyHostCount",
              ".",
              ".",
              ".",
              "."
            ]
          ]

          period = 60

          stat = "Average"

          region = "ap-south-1"

          view = "timeSeries"
        }
      },

      # ======================================================
      # alb http 5xx
      # ======================================================

      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6

        properties = {
          title = "ALB HTTP 5XX ERRORS"

          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer",
              var.alb_arn_suffix
            ]
          ]

          period = 60

          stat = "Sum"

          region = "ap-south-1"

          view = "timeSeries"
        }
      },





    ]
  })
}

