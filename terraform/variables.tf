# =============================================================================
# Variables — must match atlas-infra-base/variables.tf exactly
# =============================================================================

variable "project_name" {
  description = "Project identifier used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "aks_kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
}

variable "aks_node_count" {
  description = "Number of AKS worker nodes"
  type        = number
  default     = 1
}

variable "aks_node_size" {
  description = "VM SKU for AKS worker nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB for AKS nodes"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Cost attribution and lifecycle tags for all resources"
  type        = map(string)
  default     = {}
}