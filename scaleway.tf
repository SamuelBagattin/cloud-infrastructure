locals {
  kubernetes_cluster_name = "small-k8s-cluster"
  kubernetes_node_type    = "DEV1-M" # 4 vCPUs, 8 GB RAM
  kubernetes_version      = "1.32" # Only minor version for auto-upgrade
  kubernetes_node_count   = 3
}

# Create a VPC for the Kubernetes cluster
resource "scaleway_vpc" "k8s_vpc" {
  name = "kubernetes-vpc"
}

# Create a Private Network within the VPC
resource "scaleway_vpc_private_network" "k8s_network" {
  name   = "kubernetes-network"
  vpc_id = scaleway_vpc.k8s_vpc.id
  ipv4_subnet {
    subnet = "172.16.0.0/22"
  }
}

# Create a Kubernetes cluster
resource "scaleway_k8s_cluster" "k8s_cluster" {
  name    = local.kubernetes_cluster_name
  version = local.kubernetes_version
  cni     = "cilium"
  
  delete_additional_resources = true
  
  private_network_id = scaleway_vpc_private_network.k8s_network.id
  
  autoscaler_config {
    disable_scale_down               = false
    scale_down_delay_after_add       = "5m"
    scale_down_unneeded_time         = "10m"
    estimator                        = "binpacking"
    expander                         = "random"
    ignore_daemonsets_utilization    = true
    balance_similar_node_groups      = true
    expendable_pods_priority_cutoff  = -10
  }

  auto_upgrade {
    enable                        = true
    maintenance_window_start_hour = 3
    maintenance_window_day        = "monday"
  }
}

# Create a node pool for the Kubernetes cluster
resource "scaleway_k8s_pool" "k8s_pool" {
  cluster_id  = scaleway_k8s_cluster.k8s_cluster.id
  name        = "default-pool"
  node_type   = local.kubernetes_node_type
  size        = local.kubernetes_node_count
  autoscaling = true
  autohealing = true
  min_size    = local.kubernetes_node_count
  max_size    = local.kubernetes_node_count * 2
}

# Output the kubeconfig
output "kubeconfig" {
  value       = scaleway_k8s_cluster.k8s_cluster.kubeconfig[0].config_file
  description = "Kubernetes cluster kubeconfig"
  sensitive   = true
}

# Output the cluster ID
output "kubernetes_cluster_id" {
  value       = scaleway_k8s_cluster.k8s_cluster.id
  description = "Kubernetes cluster ID"
}

# Output the Kubernetes API server URL
output "kubernetes_api_server_url" {
  value       = scaleway_k8s_cluster.k8s_cluster.apiserver_url
  description = "Kubernetes API server URL"
}