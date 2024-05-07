resource "aws_s3_bucket" "lambda_artifacts" {
  bucket   = "samuel-lambda-artifacts"
  provider = aws.ireland
}

locals {
  current_region     = "eu-west-1"
}

