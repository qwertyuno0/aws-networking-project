
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "aws-networking-project"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

