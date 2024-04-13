module "aws_github_actions_oidc" {
  source  = "SamuelBagattin/github-oidc-provider/aws"
  version = "0.4.0"
  permissions = {
    "SamuelBagattin" : {
      role_name = "githubActions-role"
      allowed_branches = ["*"]
      allowed_environments = ["*"]
      pull_requests = true
      repositories = {
        "cloud-infrastructure" = {}
      }
    }
  }
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = "githubActions-role"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_ssm_parameter" "github_actions_oidc_provider_arn" {
  name     = "githubActions-oidcProviderArn-ssmParam"
  type     = "String"
  value    = module.aws_github_actions_oidc.oidc_provider_arn
  provider = aws.paris
}