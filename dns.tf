locals {
  dns_records = {
  }
  domain_name = "samuelbagattin.com"
}

resource "aws_route53_zone" "samuelbagattin_com" {
  name = local.domain_name
}

resource "aws_route53_record" "samuelbagattin_com" {
  for_each = local.dns_records
  name     = each.key
  type     = each.value.type
  zone_id  = aws_route53_zone.samuelbagattin_com.id
  records  = [each.value.value]
  ttl      = "60"
}

data "aws_ssm_parameter" "cloudflare_account_id" {
  name = "/cloudflare/account/id"
  with_decryption = true
}

resource "cloudflare_zone" "samuelbagattin-com" {
  zone       = local.domain_name
  jump_start = false
  account_id = data.aws_ssm_parameter.cloudflare_account_id.value
}

module "acm_certificate" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  providers = {
    aws = aws.nvirginia
  }

  domain_name = local.domain_name
  zone_id     = cloudflare_zone.samuelbagattin-com.id

  subject_alternative_names = [
    "*.${local.domain_name}"
  ]

  create_route53_records  = false
  validation_method       = "DNS"
  validation_record_fqdns = cloudflare_record.validation[*].hostname

  tags = {
    Name = local.domain_name
  }
}

resource "cloudflare_record" "validation" {
  count = length(module.acm_certificate.distinct_domain_names)

  zone_id = cloudflare_zone.samuelbagattin-com.id
  name    = element(module.acm_certificate.validation_domains, count.index)["resource_record_name"]
  type    = element(module.acm_certificate.validation_domains, count.index)["resource_record_type"]
  value   = trimsuffix(element(module.acm_certificate.validation_domains, count.index)["resource_record_value"], ".")
  ttl     = 60
  proxied = false

  allow_overwrite = true
}

data "aws_acm_certificate" "samuelbagattin" {
  domain   = local.domain_name
  provider = aws.nvirginia
  depends_on = [module.acm_certificate]
}

