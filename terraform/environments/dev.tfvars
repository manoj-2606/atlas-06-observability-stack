# =============================================================================
# Dev Environment — atlas-06-observability-stack
# =============================================================================
# 2x Standard_B2s nodes (2 vCPU, 4GB RAM each = 8GB total)
# Required because monitoring stack is resource-heavy:
#   Prometheus ~512MB + Grafana ~256MB + AlertManager ~128MB +
#   Node Exporter ~64MB + kube-state-metrics ~128MB +
#   Kubecost ~256MB + atlas-platform-app ~256MB + system pods ~500MB
#   Total: ~2.1GB — exceeds single B2s usable capacity
# Cost: 2 × $0.04/hr × 8hr = ~₹55/day
# =============================================================================

project_name           = "atlas-06"
environment            = "dev"
location               = "centralindia"
aks_kubernetes_version = "1.37.1"
aks_node_count         = 2
aks_node_size          = "Standard_B2s"
os_disk_size_gb        = 30

tags = {
  project     = "atlas-06-observability-stack"
  environment = "dev"
  team        = "platform"
  cost-center = "atlas-learning"
  created-by  = "monarch"
  managed-by  = "terraform"
  destroy-by  = "end-of-day"
}