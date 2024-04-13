module "aws_github_actions_oidc" {
  source  = "registry.terraform.io/SamuelBagattin/github-oidc-provider/aws"
  permissions = {
    "samuelbagattin" : {
      role_name = "githubActions-role"
      allowed_branches = ["main","feat/*"]
      repositories = {
        "cloud-infrastructure" = {}
        "urlite" = {}
      }
    }
  }
}

resource "aws_iam_policy_attachment" "githubactions_admin" {
  name       = "githubactions-role-admin"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  roles = [
    "githubActions-role"
  ]
  depends_on = [module.aws_github_actions_oidc]
}

resource "aws_ssm_parameter" "github_actions_oidc_provider_arn" {
  name     = "githubActions-oidcProviderArn-ssmParam"
  type     = "String"
  value    = module.aws_github_actions_oidc.oidc_provider_arn
  provider = aws.paris
}