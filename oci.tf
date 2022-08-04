data "http" "cloudfront_ip_list" {
  url = "https://d7uri8nf7uskq.cloudfront.net/tools/list-cloudfront-ips"
  request_headers = {
    "Accept" = "application/json"
  }
}

data "http" "my_ip" {
  url = "https://api.ipify.org?format=json"
  request_headers = {
    Accept = "application/json"
  }
}

locals {
  oci_compartment_id          = "ocid1.tenancy.oc1..aaaaaaaao4yh474jk2xmszte4ksyy7ghnjhna2eqsdfkuxdcbcfkjulxd6iq"
  my_ip                       = jsondecode(data.http.my_ip.body)["ip"]
  cloudfront_ip_range         = toset(sort(concat(jsondecode(data.http.cloudfront_ip_list.body)["CLOUDFRONT_GLOBAL_IP_LIST"], jsondecode(data.http.cloudfront_ip_list.body)["CLOUDFRONT_REGIONAL_EDGE_IP_LIST"])))
  chunked_cloudfront_ip_range = chunklist(local.cloudfront_ip_range, 120)
  cloudfront_dns_names        = ["grafana.samuelbagattin.com", "echo.samuelbagattin.com", "influxdb.samuelbagattin.com", "hubble.samuelbagattin.com"]
}

resource "oci_core_vcn" "main" {
  compartment_id = local.oci_compartment_id
  cidr_block     = "172.16.0.0/16"
  display_name   = "main"
  dns_label      = "main"
}
resource "oci_core_subnet" "main" {
  cidr_block        = "172.16.0.0/24"
  compartment_id    = local.oci_compartment_id
  vcn_id            = oci_core_vcn.main.id
  security_list_ids = flatten([oci_core_security_list.from_cloudfront[*].id, oci_core_security_list.from_me.id])
  route_table_id    = oci_core_route_table.main.id
}
resource "oci_core_internet_gateway" "main" {
  compartment_id = local.oci_compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "main"
}
resource "oci_core_route_table" "main" {
  compartment_id = local.oci_compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "main"
  route_rules {
    network_entity_id = oci_core_internet_gateway.main.id
    destination_type  = "CIDR_BLOCK"
    destination       = "0.0.0.0/0"
  }
}


data "oci_core_image" "default" {
  image_id = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaakkun23rbrjkobpjo4hnewajqqvfhuyqzbk2mzj3uqhoavnuwhcpq"
}

resource "oci_core_instance" "instance" {
  availability_domain = "MtQI:EU-FRANKFURT-1-AD-3"
  compartment_id      = oci_core_subnet.main.compartment_id
  shape               = "VM.Standard.A1.Flex"
  shape_config {
    memory_in_gbs = 24
    ocpus         = 4
  }
  create_vnic_details {
    skip_source_dest_check = true
    subnet_id              = oci_core_subnet.main.id
    nsg_ids                = []
  }

  metadata = {
    "ssh_authorized_keys" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCgsQc4VEia8PvIY0OQf12II8fFp4a4/ZdDaddAi09DozNWOyWyYbMELDvvZT57uXR8KrPOj9fgBmsk0xIwncA1TTJ8KbO5EuAqOnvMvxJxlMTSxI4jg30a10Ff8XWMTKlHvqGOhNDdbUWvXhVUrs6E1lc12eiyM2iDtbWI9ABI9ey6M7bYZdDdAQfQg7+IWjNdtAnOQzhxpAxk2yPe/S+WxLMru0Zmv1CC975vFUY0WFY9rXCGfT1OswphuySBQpoF7f6cF/E4F9fWxkXnrY5KjupnlHLGVVDcblnuQBT9J/VqDwFfAVi9F9xTFR0R0Bk7yZzIXhWlIQuAkCKqoduF ssh-key-2021-12-15"
  }

  source_details {
    source_id   = data.oci_core_image.default.id
    source_type = "image"
  }

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false

    plugins_config {
      desired_state = "DISABLED"
      name          = "Vulnerability Scanning"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "OS Management Service Agent"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Run Command"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Block Volume Management"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Bastion"
    }
  }
}

resource "oci_core_security_list" "from_cloudfront" {
  count          = length(local.chunked_cloudfront_ip_range)
  compartment_id = oci_core_vcn.main.compartment_id
  vcn_id         = oci_core_vcn.main.id

  egress_security_rules {
    destination      = "0.0.0.0/0"
    protocol         = "all"
    destination_type = "CIDR_BLOCK"
    stateless        = false
  }

  dynamic "ingress_security_rules" {
    for_each = local.chunked_cloudfront_ip_range[count.index]
    iterator = cidr
    content {
      protocol    = "6"
      source      = cidr.value
      source_type = "CIDR_BLOCK"
      stateless   = false
      tcp_options {
        max = 80
        min = 80
      }
    }
  }
}

resource "oci_core_security_list" "from_me" {
  compartment_id = local.oci_compartment_id
  vcn_id         = oci_core_vcn.main.id

  egress_security_rules {
    destination      = "0.0.0.0/0"
    protocol         = "all"
    destination_type = "CIDR_BLOCK"
    stateless        = false
  }

  ingress_security_rules {
    protocol    = "all"
    source_type = "CIDR_BLOCK"
    source      = "0.0.0.0/0"
    stateless   = false
  }
}

resource "aws_cloudfront_distribution" "oci_instance" {
  enabled = true
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "oci-instance"
    viewer_protocol_policy = "redirect-to-https"
    max_ttl                = 0
    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }
  }
  aliases = local.cloudfront_dns_names
  origin {
    domain_name = aws_route53_record.samuelbagattin_com["oci.samuelbagattin.com"].name
    origin_id   = "oci-instance"
    custom_origin_config {
      http_port              = 32080
      https_port             = 32443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.samuelbagattin.arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_route53_record" "cloudfront_oci_A" {
  for_each = { for v in local.cloudfront_dns_names : v => v }
  name     = each.value
  type     = "A"
  zone_id  = aws_route53_zone.samuelbagattin_com.id
  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.oci_instance.domain_name
    zone_id                = aws_cloudfront_distribution.oci_instance.hosted_zone_id
  }
}
resource "aws_route53_record" "cloudfront_oci_AAAA" {
  for_each = { for v in local.cloudfront_dns_names : v => v }
  name     = each.value
  type     = "AAAA"
  zone_id  = aws_route53_zone.samuelbagattin_com.id
  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.oci_instance.domain_name
    zone_id                = aws_cloudfront_distribution.oci_instance.hosted_zone_id
  }
}
