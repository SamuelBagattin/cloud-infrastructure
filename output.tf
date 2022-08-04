#output "load_balancer_ips" {
#  value = oci_network_load_balancer_network_load_balancer.main.ip_addresses
#}

output "instance_ip" {
  value = oci_core_instance.instance.public_ip
}

output "ssh_private_key_path" {
  value = var.oci_private_key_path
}

output "github_actions_roles_arns" {
  value = module.aws_github_actions_oidc.roles_arns
}

output "oci_ssm_activation" {
  value = {
   activation_code = aws_ssm_activation.oci.activation_code
    activation_id = aws_ssm_activation.oci.id
  }
}