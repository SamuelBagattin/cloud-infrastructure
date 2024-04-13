module "aws_github_actions_oidc" {
  source  = "registry.terraform.io/SamuelBagattin/github-oidc-provider/aws"
  permissions = {
    "samuelbagattin" : {
      role_name = "githubActions-role"
      allowed_branches = ["*"]
      repositories = {
        "cloud-infrastructure" = {}
        "urlite" = {}
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