# PromQL Cheatsheet — Atlas Platform App

## Core Concepts

| Concept | What It Means | Example |
|---------|--------------|---------|
| **Counter** | Only goes up (resets on restart). Total count of events. | `http_requests_total` |
| **Gauge** | Goes up and down. Current value. | `node_memory_MemAvailable_bytes` |
| **Histogram** | Counts observations in configurable buckets. | `http_request_duration_seconds_bucket` |
| **rate()** | Per-second rate of a counter over a time window. | `rate(http_requests_total[5m])` |
| **increase()** | Total increase of a counter over a time window. | `increase(restarts_total[1h])` |
| **histogram_quantile()** | Calculates percentile from histogram buckets. | `histogram_quantile(0.95, ...)` |
| **sum()** | Aggregates across all label combinations. | `sum(rate(...))` |
| **by()** | Groups aggregation by specific labels. | `sum(...) by (pod)` |

## 5 Dashboard Queries — Explained

### 1. Request Rate (requests per second)

```promql
sum(rate(http_requests_total{namespace="dev"}[5m]))
```

**What each part does:**
- `http_requests_total` — counter metric, increments on every request
- `{namespace="dev"}` — label filter, only dev namespace
- `[5m]` — look at the last 5 minutes of data points
- `rate()` — converts counter to per-second rate (handles counter resets)
- `sum()` — aggregates across all status codes, methods, paths

**Why 5m window?** Shorter windows (1m) are noisy. Longer windows (15m) hide spikes. 5m is the standard balance.

**Panel type:** Time series (line graph) — shows request rate over time.

---

### 2. Error Rate Percentage

```promql
sum(rate(http_requests_total{status=~"5..", namespace="dev"}[5m]))
/
sum(rate(http_requests_total{namespace="dev"}[5m]))
* 100
```

**What each part does:**
- `status=~"5.."` — regex match for 5xx status codes (500, 502, 503, etc.)
- Numerator: rate of 5xx responses
- Denominator: rate of ALL responses
- `* 100` — convert ratio to percentage

**Why this matters:** This IS the Availability SLI. SLO says < 0.1%. Alert fires at > 1%.

**Panel type:** Stat (single number, color-coded: green/yellow/red).

---

### 3. P95 Latency

```promql
histogram_quantile(0.95,
  sum(rate(http_request_duration_seconds_bucket{namespace="dev"}[5m])) by (le)
)
```

**What each part does:**
- `http_request_duration_seconds_bucket` — histogram metric with `le` (less-than-or-equal) labels
- `rate(...[5m])` — per-second rate of observations falling into each bucket
- `sum(...) by (le)` — aggregate across all instances, keeping bucket boundaries
- `histogram_quantile(0.95, ...)` — interpolates the value where 95% of observations fall below
- `le` — required for `histogram_quantile()` to work. NEVER drop it.

**Common mistake:** Forgetting `by (le)` in the inner query. Without it, `histogram_quantile` has no bucket boundaries to work with and returns `NaN`.

**Panel type:** Time series with a threshold line at 200ms (SLO target).

---

### 4. Pod Restart Count (last hour)

```promql
sum(increase(kube_pod_container_status_restarts_total{namespace="dev"}[1h]))
```

**What each part does:**
- `kube_pod_container_status_restarts_total` — counter from kube-state-metrics
- `[1h]` — look at the last hour
- `increase()` — how much the counter went up in that window
- `sum()` — total across all pods in dev namespace

**Why increase() not rate()?** `rate()` gives per-second rate (0.0008 restarts/sec is meaningless). `increase()` gives the actual count (3 restarts in 1 hour is actionable).

**Panel type:** Stat (single number, red if > 0).

---

### 5. Error Budget Burn Rate

```promql
1 - (
  sum(rate(http_requests_total{status!~"5..", namespace="dev"}[1h]))
  /
  sum(rate(http_requests_total{namespace="dev"}[1h]))
)
```

**What each part does:**
- Inner fraction: success rate (non-5xx / total) over 1 hour
- `1 - success_rate` = error rate as a decimal
- SLO: 99.9% → budget: 0.001
- If this value > 0.001, you're burning budget faster than allowed

**How to interpret:**
- `0.000` — perfect, no errors
- `0.0005` — burning budget at 0.5x (sustainable)
- `0.001` — at the SLO edge (warning)
- `0.01` — burning at 10x (critical — budget exhausted in ~4 hours)

**Panel type:** Gauge (0 to 0.01 range, red zone > 0.001).

## Infrastructure Queries

### Node CPU Usage %

```promql
100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**How it works:** `node_cpu_seconds_total` counts CPU-seconds per mode (idle, user, system...). `rate()` on `mode="idle"` gives fraction of time CPU was idle. `100 - idle% = usage%`.

### Node Memory Usage %

```promql
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100
```

**How it works:** `MemAvailable` is what the kernel considers available for new allocations (includes reclaimable caches). This is more accurate than `MemFree`.

### Pod CPU Usage (per pod)

```promql
sum(rate(container_cpu_usage_seconds_total{namespace="dev", container!=""}[5m])) by (pod)
```

**Why `container!=""`?** Filters out the pause container (infrastructure container in every pod). Without this filter, you'd double-count.

## Interview Quick-Fire

| Question | Answer |
|----------|--------|
| rate() vs increase()? | rate = per-second average. increase = total count over window. rate for graphs, increase for "how many". |
| Why not avg for latency? | Averages hide outliers. P95 shows what 95% of users experience. |
| What's `le` in histograms? | "Less than or equal" — bucket boundary labels. Required for histogram_quantile. |
| Counter vs Gauge? | Counter only goes up (use rate/increase). Gauge goes up/down (use directly). |
| What happens on counter reset? | rate() and increase() handle resets automatically — they detect decreases and adjust. |
| Why 5m window? | Balance: 1m is noisy, 15m smooths too much. 5m is the Prometheus community standard. |