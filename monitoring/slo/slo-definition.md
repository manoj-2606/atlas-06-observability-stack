# SLI/SLO Definition — atlas-platform-app

## Concepts

| Term | Definition | Example |
|------|-----------|---------|
| **SLI** (Service Level Indicator) | A quantitative measure of a service attribute | "% of requests returning non-5xx" |
| **SLO** (Service Level Objective) | A target value for an SLI | "99.9% of requests return non-5xx" |
| **Error Budget** | How much failure is allowed before SLO breach | "0.1% = 43.2 minutes/month of downtime" |
| **Burn Rate** | How fast the error budget is being consumed | "10x burn = budget exhausted in 3 days" |

## SLO Definitions

### Availability SLO

| Field | Value |
|-------|-------|
| **SLI** | Proportion of successful HTTP requests (non-5xx) |
| **SLO Target** | 99.9% over 30-day rolling window |
| **Error Budget** | 0.1% = 43.2 minutes of downtime per 30 days |
| **Measurement** | `sum(rate(http_requests_total{status!~"5.."}[1h])) / sum(rate(http_requests_total[1h]))` |
| **Alert Threshold** | Error rate > 1% for 2 minutes → Critical |

### Latency SLO (P95)

| Field | Value |
|-------|-------|
| **SLI** | 95th percentile HTTP response time |
| **SLO Target** | P95 < 200ms |
| **Measurement** | `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))` |
| **Alert Threshold** | P95 > 500ms for 2 minutes → Warning |

### Latency SLO (P99)

| Field | Value |
|-------|-------|
| **SLI** | 99th percentile HTTP response time |
| **SLO Target** | P99 < 500ms |
| **Measurement** | `histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))` |

## Error Budget Calculation

```
Error Budget = 1 - SLO Target
             = 1 - 0.999
             = 0.001 (0.1%)

In a 30-day window:
  Total minutes = 30 × 24 × 60 = 43,200
  Budget = 43,200 × 0.001 = 43.2 minutes

Burn rate formula:
  burn_rate = actual_error_rate / budget_error_rate
  Example: 1% error rate / 0.1% budget = 10x burn
  At 10x burn: budget exhausted in 43.2 / 10 = 4.32 minutes
```

## Dashboard Panels Tied to SLOs

| Panel | SLI It Tracks | SLO | Alert |
|-------|--------------|-----|-------|
| Error Rate % | Availability | 99.9% | HighErrorRate (critical) |
| P95 Latency | Latency | < 200ms | HighLatencyP95 (warning) |
| Error Budget Burn | Burn rate | < 0.001 | ErrorBudgetBurnHigh (warning) |
| Pod Restarts | Stability | 0 restarts | PodCrashLooping (critical) |

## Interview Talking Points

1. **"What's the difference between SLI and SLO?"**
   SLI is the measurement (error rate). SLO is the target (99.9%).

2. **"How do you calculate error budget?"**
   1 - SLO target. For 99.9%, budget is 0.1% = 43.2 min/month.

3. **"What happens when error budget is exhausted?"**
   Freeze feature releases. Focus on reliability. This is the SRE contract.

4. **"Why burn rate over raw error rate?"**
   Burn rate is velocity. 0.5% error rate means nothing without context.
   At 5x burn, you have days. At 100x burn, you have minutes.

5. **"How do you choose SLO targets?"**
   Based on user expectations and business impact. 99.9% is common for
   internal services. 99.95%+ for user-facing. Never 100% — that's unachievable.