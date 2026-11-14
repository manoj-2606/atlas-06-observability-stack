#!/bin/bash
# =============================================================================
# Generate Load — populate Prometheus metrics for Grafana dashboard demo
# =============================================================================
# Run AFTER deployment from your local machine:
#   az aks get-credentials --resource-group rg-atlas-06-dev --name aks-atlas-06-dev
#   chmod +x scripts/generate-load.sh
#   ./scripts/generate-load.sh
#
# What it does:
#   1. Hits /health 200 times rapidly → populates request_rate and latency metrics
#   2. Hits /simulate/load → generates CPU pressure → populates node CPU panel
#   3. Wait, then verify metrics exist via /metrics endpoint
# =============================================================================

set -e

NAMESPACE="dev"
APP_LABEL="app.kubernetes.io/name=atlas-platform"

echo "=== Atlas-06: Generating Load ==="

# Get pod name
POD=$(kubectl get pods -n "$NAMESPACE" -l "$APP_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ]; then
  echo "ERROR: No pod found with label $APP_LABEL in namespace $NAMESPACE"
  exit 1
fi
echo "Target pod: $POD"

# --- Phase 1: Generate request metrics ---
echo ""
echo "--- Phase 1: Generating HTTP request metrics (200 requests) ---"
for i in $(seq 1 200); do
  kubectl exec "$POD" -n "$NAMESPACE" -- \
    python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" \
    &>/dev/null &

  # Print progress every 50 requests
  if [ $((i % 50)) -eq 0 ]; then
    echo "  Sent $i / 200 requests..."
  fi
done
wait
echo "  Done. 200 requests sent."

# --- Phase 2: Generate CPU load ---
echo ""
echo "--- Phase 2: Triggering CPU load (POST /simulate/load) ---"
kubectl exec "$POD" -n "$NAMESPACE" -- \
  python -c "
import urllib.request, json
req = urllib.request.Request(
    'http://localhost:8000/simulate/load',
    data=json.dumps({'cpu': 50, 'duration': 30}).encode(),
    headers={'Content-Type': 'application/json'},
    method='POST'
)
resp = urllib.request.urlopen(req)
print(f'  Response: {resp.read().decode()}')
"
echo "  CPU load triggered for 30 seconds."

# --- Phase 3: Verify metrics exist ---
echo ""
echo "--- Phase 3: Verifying /metrics endpoint ---"
sleep 5
kubectl exec "$POD" -n "$NAMESPACE" -- \
  python -c "
import urllib.request
data = urllib.request.urlopen('http://localhost:8000/metrics').read().decode()
lines = [l for l in data.split('\n') if not l.startswith('#') and l.strip()]
print(f'  Metrics exported: {len(lines)} time series')
# Show first 5 metric names
seen = set()
for l in data.split('\n'):
    if not l.startswith('#') and l.strip():
        name = l.split('{')[0].split(' ')[0]
        if name not in seen:
            seen.add(name)
            if len(seen) <= 10:
                print(f'    - {name}')
if len(seen) > 10:
    print(f'    ... and {len(seen) - 10} more')
"

echo ""
echo "=== Load generation complete ==="
echo "Open Grafana to see metrics: kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring"
echo "Login: admin / atlas-admin"