provider "aws" {
  region  = local.current_region
  profile = var.aws_profile
  default_tags {
    tags = {
      git-repository : "cloud-infrastructure"
    }
  }
}

provider "aws" {
  region  = "eu-west-3"
  alias   = "paris"
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

data "aws_ssm_parameter" "cloudflare_token" {
  name            = "/cloudflare/api/token"
  with_decryption = true
}

data "aws_ssm_parameter" "oci_tenancy_ocid" {
  name            = "/oci/tenancy/ocid"
  with_decryption = true
}
data "aws_ssm_parameter" "oci_private_key" {
  name            = "/oci/private_key"
  with_decryption = true
}
data "aws_ssm_parameter" "oci_user_ocid" {
  name            = "/oci/user/ocid"
  with_decryption = true
}
data "aws_ssm_parameter" "oci_fingerprint" {
  name            = "/oci/fingerprint"
  with_decryption = true
}

provider "oci" {
  region       = "eu-frankfurt-1"
  private_key = data.aws_ssm_parameter.oci_private_key.value
  tenancy_ocid = data.aws_ssm_parameter.oci_tenancy_ocid.value
  user_ocid    = data.aws_ssm_parameter.oci_user_ocid.value
  fingerprint  = data.aws_ssm_parameter.oci_fingerprint.value
}

provider "cloudflare" {
  api_token = data.aws_ssm_parameter.cloudflare_token.value
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
    cloudflare = {
      source  = "cloudflare/cloudflare"
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
