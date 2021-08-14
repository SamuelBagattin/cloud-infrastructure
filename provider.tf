provider "aws" {
  region = "eu-west-3"
}

terraform {
  required_version = ">=0.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket  = "samuel-terraform-states"
    encrypt = "true"
    key     = "cloud-infrastructure.tfstate"
    region  = "eu-west-3"
  }
}
