# =============================================================================
# Atlas-06: Observability Stack — Infrastructure
# =============================================================================
# Uses atlas-infra-base module to provision AKS (2 nodes) + ACR + VNet
# 2 nodes required: monitoring stack (Prometheus + Grafana + AlertManager +
# Kubecost) is resource-heavy — won't fit on a single B2s (4GB RAM)
# =============================================================================

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.14"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-atlas-tfstate"
    storage_account_name = "atlastfstate2606"
    container_name       = "tfstate"
    key                  = "atlas-06.tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}

# =============================================================================
# Infrastructure — atlas-infra-base module
# =============================================================================

module "infra" {
  source = "git::https://github.com/manoj-2606/atlas-infra-base.git"

  project_name           = var.project_name
  environment            = var.environment
  location               = var.location
  aks_kubernetes_version = var.aks_kubernetes_version
  aks_node_count         = var.aks_node_count
  aks_node_size          = var.aks_node_size
  os_disk_size_gb        = var.os_disk_size_gb
  tags                   = var.tags
}