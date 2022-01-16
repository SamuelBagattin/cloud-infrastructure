provider "aws" {
  region = "eu-west-3"
  token  = var.aws_session_token
}

provider "oci" {
  region           = "eu-frankfurt-1"
  private_key_path = var.oci_private_key_path
  tenancy_ocid     = var.oci_tenancy_ocid
  user_ocid        = var.oci_user_ocid
  fingerprint      = var.oci_fingerprint
}

terraform {
  required_version = ">=1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    oci = {
      source  = "SamuelBagattin/oci"
      version = "4.58.0-2"
    }
  }
  backend "s3" {
    bucket  = "samuel-terraform-states"
    encrypt = "true"
    key     = "cloud-infrastructure.tfstate"
    region  = "eu-west-3"
  }
}
