#output "load_balancer_ips" {
#  value = oci_network_load_balancer_network_load_balancer.main.ip_addresses
#}

output "instance_ip" {
  value = oci_core_instance.instance.public_ip
}

output "github_actions_roles_arns" {
  value = module.aws_github_actions_oidc.roles_arns
}
