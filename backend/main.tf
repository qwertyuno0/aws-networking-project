# s3 bucket for remote terraform state

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "devops-project-aws-tf-01"
  force_destroy = true
  tags = {
    Name        = "terraform state bucket"
    Environment = "dev"
    Project     = "aws-networking-project"
  }
}

# enable versioning on the bucket

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}


# enable server-side encryption

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#block all public access
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}




# outputs

output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

