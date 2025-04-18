resource "aws_s3_bucket" "lambda_artifacts" {
  bucket   = "samuel-lambda-artifacts"
  provider = aws.ireland
}

locals {
  current_region     = "eu-west-1"
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = "awssam-artifacts-bucket"

  # Allow deletion of non-empty bucket during terraform destroy
  force_destroy = true

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # S3 Bucket Ownership Controls
  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    status = "Suspended"
  }
}

