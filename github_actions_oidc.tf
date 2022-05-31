module "aws_github_actions_oidc" {
  source  = "registry.terraform.io/SamuelBagattin/github-oidc-provider/aws"
  version = "0.3.3"
  create_oidc_provider = true
  create_iam_roles     = false
  permissions          = {}
}

resource "aws_ssm_parameter" "github_actions_oidc_provider_arn" {
  name  = "githubActions-oidcProviderArn-ssmParam"
  type  = "String"
  value = module.aws_github_actions_oidc.oidc_provider_arn
}