locals {
  dns_records = {
  }
}

resource "aws_route53_zone" "samuelbagattin_com" {
  name = "samuelbagattin.com"
}

resource "aws_route53_record" "samuelbagattin_com" {
  for_each = local.dns_records
  name     = each.key
  type     = each.value.type
  zone_id  = aws_route53_zone.samuelbagattin_com.id
  records  = [each.value.value]
  ttl      = "60"
}

data "aws_acm_certificate" "samuelbagattin" {
  domain   = "samuelbagattin.com"
  provider = aws.nvirginia
}

data "aws_ssm_parameter" "cloudflare_account_id" {
  name = "/cloudflare/account/id"
  with_decryption = true
}

resource "cloudflare_zone" "samuelbagattin-com" {
  zone       = "samuelbagattin.com"
  jump_start = false
  account_id = data.aws_ssm_parameter.cloudflare_account_id.value
}

