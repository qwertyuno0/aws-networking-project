# Intentionally has no permission policies.
# The instances run in private subnets with no NAT and no VPC endpoints, so they
# cannot call AWS APIs, and nothing running on them needs to. The role and
# instance profile are the attachment point for SSM Session Manager or the
# CloudWatch agent once VPC endpoints are added.



# ------------------
# iam role for ec2
# -----------------

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {

        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}


# -----------------------------------
# EC2 Instance Profile
# -----------------------------------

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"

  role = aws_iam_role.ec2.name

  tags = {
    Name = "${var.project_name}-ec2-profile"
  }
}
