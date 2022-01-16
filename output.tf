#output "load_balancer_ips" {
#  value = oci_network_load_balancer_network_load_balancer.main.ip_addresses
#}

output "instance_ip" {
  value = oci_core_instance.instance.public_ip
}