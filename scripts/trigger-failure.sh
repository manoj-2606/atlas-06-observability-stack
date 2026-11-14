#!/bin/bash
# =============================================================================
# Trigger Failure — test PrometheusRule alerts fire correctly
# =============================================================================
# Run AFTER deployment + load generation:
#   chmod +x scripts/trigger-failure.sh
#   ./scripts/trigger-failure.sh
#
# What it does:
#   1. Sends requests that trigger 5xx errors → fires HighErrorRate alert
#   2. Shows how to check AlertManager for firing alerts
#   3. Does NOT trigger OOM/CrashLoop (those kill the pod — do manually if needed)
# =============================================================================

set -e

NAMESPACE="dev"
APP_LABEL="app.kubernetes.io/name=atlas-platform"

echo "=== Atlas-06: Triggering Failures for Alert Testing ==="

# Get pod name
POD=$(kubectl get pods -n "$NAMESPACE" -l "$APP_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ]; then
  echo "ERROR: No pod found with label $APP_LABEL in namespace $NAMESPACE"
  exit 1
fi
echo "Target pod: $POD"

# --- Phase 1: Trigger 5xx errors ---
echo ""
echo "--- Phase 1: Triggering 5xx errors (POST /simulate/failure) ---"
echo "  Sending 50 failure requests to push error rate above 1%..."
for i in $(seq 1 50); do
  kubectl exec "$POD" -n "$NAMESPACE" -- \
    python -c "
import urllib.request
try:
    req = urllib.request.Request('http://localhost:8000/simulate/failure', method='POST')
    urllib.request.urlopen(req)
except Exception:
    pass  # Expected — the endpoint returns errors
" &>/dev/null &
done
wait
echo "  Done. 50 failure requests sent."

# --- Phase 2: Check alert status ---
echo ""
echo "--- Phase 2: Wait 2-3 minutes for alerts to fire, then check ---"
echo ""
echo "Check alerts via kubectl:"
echo "  kubectl get prometheusrule -n monitoring"
echo "  kubectl port-forward svc/kube-prometheus-stack-alertmanager 9093:9093 -n monitoring"
echo "  Open: http://localhost:9093/#/alerts"
echo ""
echo "Check in Grafana:"
echo "  kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring"
echo "  Open: http://localhost:3000 → Alerting → Alert rules"
echo ""
echo "Check in Prometheus UI:"
echo "  kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring"
echo "  Open: http://localhost:9090/alerts"
echo ""
echo "=== Failure injection complete. Alerts should fire within 2-3 minutes. ==="