
locals {
  oci_compartment_id          = "ocid1.tenancy.oc1..aaaaaaaao4yh474jk2xmszte4ksyy7ghnjhna2eqsdfkuxdcbcfkjulxd6iq"
  cloudfront_dns_names        = []
  ports_configuration = {
    nginx_ingress_controller_http  = 32080
    nginx_ingress_controller_https = 32443
    ssh                            = 22
    openvpn_ui                     = 943
    openvpn                        = 443
  }
}

resource "oci_core_vcn" "main" {
  compartment_id = local.oci_compartment_id
  cidr_block     = "172.16.0.0/16"
  display_name   = "main"
  dns_label      = "main"
}

resource "oci_core_subnet" "main" {
  display_name   = "main"
  cidr_block     = "172.16.0.0/24"
  compartment_id = local.oci_compartment_id
  vcn_id         = oci_core_vcn.main.id
  security_list_ids = [
    oci_core_security_list.from_me.id
  ]
  route_table_id = oci_core_route_table.main.id
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

data "oci_core_image" "vpn_server" {
  image_id = "ocid1.image.oc1..aaaaaaaa4ozqggnywlp3e3wzvu5x3aoohkt6cwm2pumgpn2tlzroj756azma"
}

resource "oci_core_instance" "instance" {
  display_name        = "instance"
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
    nsg_ids                = [oci_core_network_security_group.instance.id]
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
resource "oci_core_instance" "vpn_server" {
  display_name        = "vpn-server"
  availability_domain = "MtQI:EU-FRANKFURT-1-AD-2"
  compartment_id      = oci_core_subnet.main.compartment_id
  shape               = "VM.Standard.E2.1.Micro"

  shape_config {
    memory_in_gbs = 1
    ocpus         = 1
  }
  create_vnic_details {
    skip_source_dest_check = false
    subnet_id              = oci_core_subnet.main.id
    nsg_ids                = [oci_core_network_security_group.vpn_server.id]
  }

  metadata = {
    "ssh_authorized_keys" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCgsQc4VEia8PvIY0OQf12II8fFp4a4/ZdDaddAi09DozNWOyWyYbMELDvvZT57uXR8KrPOj9fgBmsk0xIwncA1TTJ8KbO5EuAqOnvMvxJxlMTSxI4jg30a10Ff8XWMTKlHvqGOhNDdbUWvXhVUrs6E1lc12eiyM2iDtbWI9ABI9ey6M7bYZdDdAQfQg7+IWjNdtAnOQzhxpAxk2yPe/S+WxLMru0Zmv1CC975vFUY0WFY9rXCGfT1OswphuySBQpoF7f6cF/E4F9fWxkXnrY5KjupnlHLGVVDcblnuQBT9J/VqDwFfAVi9F9xTFR0R0Bk7yZzIXhWlIQuAkCKqoduF ssh-key-2021-12-15"
  }

  source_details {
    source_id   = data.oci_core_image.vpn_server.id
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
/*
resource "oci_core_security_list" "from_cloudfront" {
  count          = length(local.chunked_cloudfront_ip_range)
  compartment_id = oci_core_vcn.main.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name = "from_cloudfront_${count.index}"

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
        max = local.ports_configuration.nginx_ingress_controller_http
        min = local.ports_configuration.nginx_ingress_controller_http
      }
    }
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
        max = local.ports_configuration.nginx_ingress_controller_https
        min = local.ports_configuration.nginx_ingress_controller_https
      }
    }
  }
}
*/
resource "oci_core_security_list" "from_me" {
  compartment_id = local.oci_compartment_id
  vcn_id         = oci_core_vcn.main.id

  display_name = "main"

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

resource "oci_core_network_security_group" "instance" {
  compartment_id = local.oci_compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "instance"
}

resource "oci_core_network_security_group_security_rule" "http" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.instance.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  stateless                 = false
  tcp_options {
    destination_port_range {
      max = local.ports_configuration.nginx_ingress_controller_http
      min = local.ports_configuration.nginx_ingress_controller_http
    }
  }
}

resource "oci_core_network_security_group_security_rule" "https" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.instance.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  stateless                 = false
  tcp_options {
    destination_port_range {
      max = local.ports_configuration.nginx_ingress_controller_https
      min = local.ports_configuration.nginx_ingress_controller_https
    }
  }
}

resource "oci_core_network_security_group" "vpn_server" {
  compartment_id = local.oci_compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "vpn_server"
}

resource "oci_core_network_security_group_security_rule" "openvpn" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.vpn_server.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  stateless                 = false
  tcp_options {
    destination_port_range {
      max = local.ports_configuration.openvpn
      min = local.ports_configuration.openvpn
    }
  }
}

resource "oci_core_network_security_group_security_rule" "openvpn_ui" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.vpn_server.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  stateless                 = false
  tcp_options {
    destination_port_range {
      max = local.ports_configuration.openvpn_ui
      min = local.ports_configuration.openvpn_ui
    }
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
    domain_name = "oci.samuelbagattin.com"
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
  http_version = "http2and3"
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

resource "aws_ssm_parameter" "oci_instance_ip" {
  name  = "/oci/instance/ip"
  type  = "String"
  value = oci_core_instance.instance.public_ip
}
