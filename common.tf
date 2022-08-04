resource "aws_s3_bucket" "lambda_artifacts" {
  bucket   = "samuel-lambda-artifacts"
  provider = aws.ireland
}

data "aws_caller_identity" "current" {}

locals {
  current_account_id = data.aws_caller_identity.current.account_id
  current_region     = "eu-west-1"
}

