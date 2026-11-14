# =============================================================================
# Outputs — consumed by pipeline for Docker push, Helm deploy, kubectl
# =============================================================================

output "resource_group_name" {
  description = "Resource group name for AKS credential retrieval"
  value       = module.infra.resource_group_name
}

output "acr_login_server" {
  description = "ACR login server for docker push"
  value       = module.infra.acr_login_server
}

output "acr_name" {
  description = "ACR name for az acr login"
  value       = module.infra.acr_name
}

output "aks_cluster_name" {
  description = "AKS cluster name for az aks get-credentials"
  value       = module.infra.aks_cluster_name
}