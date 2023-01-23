provider "aws" {
  region  = local.current_region
  profile = var.aws_profile
  default_tags {
    tags = {
      git-repository: "cloud-infrastructure"
    }
  }
}

provider "aws" {
  region  = "eu-west-3"
  alias = "paris"
  profile = var.aws_profile
}

provider "aws" {
  region  = "eu-west-1"
  alias   = "ireland"
  profile = var.aws_profile
}

provider "aws" {
  region  = "us-east-1"
  alias   = "nvirginia"
  profile = var.aws_profile
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
      version = "~> 4.0"
    }
    oci = {
      source  = "oracle/oci"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket  = "samuel-terraform-states"
    encrypt = "true"
    key     = "cloud-infrastructure.tfstate"
    region  = "eu-west-3"
  }
}
