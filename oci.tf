data "oci_core_subnet" "default" {
  subnet_id = "ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaakhpo5hkyeepbyb2chge4mo2hbnin5keukyvnjtwp32b554zdrnkq"
}

resource "oci_core_instance" "instance" {
  availability_domain = "MtQI:EU-FRANKFURT-1-AD-3"
  compartment_id      = data.oci_core_subnet.default.compartment_id
  shape               = "VM.Standard.A1.Flex"
  create_vnic_details {
    skip_source_dest_check = true
    nsg_ids = []
  }
  metadata = {
    "ssh_authorized_keys" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCgsQc4VEia8PvIY0OQf12II8fFp4a4/ZdDaddAi09DozNWOyWyYbMELDvvZT57uXR8KrPOj9fgBmsk0xIwncA1TTJ8KbO5EuAqOnvMvxJxlMTSxI4jg30a10Ff8XWMTKlHvqGOhNDdbUWvXhVUrs6E1lc12eiyM2iDtbWI9ABI9ey6M7bYZdDdAQfQg7+IWjNdtAnOQzhxpAxk2yPe/S+WxLMru0Zmv1CC975vFUY0WFY9rXCGfT1OswphuySBQpoF7f6cF/E4F9fWxkXnrY5KjupnlHLGVVDcblnuQBT9J/VqDwFfAVi9F9xTFR0R0Bk7yZzIXhWlIQuAkCKqoduF ssh-key-2021-12-15"
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

resource "oci_core_default_security_list" "default" {
  manage_default_resource_id = data.oci_core_subnet.default.security_list_ids[0]
  ingress_security_rules {
    protocol    = "all"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
  }
  egress_security_rules {
    destination      = "0.0.0.0/0"
    protocol         = "all"
    destination_type = "CIDR_BLOCK"
    stateless        = false
  }

}

resource "oci_core_network_security_group" "main" {
  compartment_id = data.oci_core_subnet.default.compartment_id
  vcn_id         = data.oci_core_subnet.default.vcn_id
  display_name   = "main"
}

resource "oci_core_network_security_group_security_rule" "ingress" {
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.main.id
  protocol                  = "all"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "egress" {
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.main.id
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_network_load_balancer_network_load_balancer" "main" {
  compartment_id                 = data.oci_core_subnet.default.compartment_id
  display_name                   = "main-nlb"
  subnet_id                      = data.oci_core_subnet.default.id
  is_preserve_source_destination = false
  is_private                     = false
  network_security_group_ids     = [oci_core_network_security_group.main.id]
  freeform_tags = {
    Name : "main-nlb"
  }
}

resource "oci_network_load_balancer_listener" "http" {
  default_backend_set_name = oci_network_load_balancer_backend_set.instance_http.name
  name                     = "http-listener"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
#  port                     = 80
  protocol                 = "ANY"
  port                     = 0
}

resource "oci_network_load_balancer_backend" "instance_http" {
  backend_set_name         = oci_network_load_balancer_backend_set.instance_http.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  port                     = 0
  ip_address               = oci_core_instance.instance.private_ip
  #  target_id = data.oci_core_instance.instance.id
  name = "instance-http-backend"
}

resource "oci_network_load_balancer_backend_set" "instance_http" {
  name                     = "instance-http-backendset"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.main.id
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true
  health_checker {
    protocol = "TCP"
    port     = 80
  }
}