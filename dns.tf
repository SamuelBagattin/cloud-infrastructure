locals {
  dns_records = {
    "oci.samuelbagattin.com" = {
      type : "A",
      value : oci_core_instance.instance.public_ip
    }
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

resource "cloudflare_zone" "samuelbagattin-com" {
  zone = "samuelbagattin.com"
  jump_start = false
}