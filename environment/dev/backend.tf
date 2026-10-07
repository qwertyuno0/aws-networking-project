terraform {
  backend "s3" {
    bucket       = "devops-project-aws-tf-01"
    key          = "networking-project/dev/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}

