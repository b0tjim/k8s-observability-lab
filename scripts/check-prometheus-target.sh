#!/usr/bin/env bash
# Assert Prometheus is scraping the app: port-forward Prometheus and poll until up == 1 for the app's Service.
#
# Usage: scripts/check-prometheus-target.sh   (after `make monitoring-up` and `make install` with the ServiceMonitor enabled)
set -euo pipefail

PROM_SVC="${PROM_SVC:-svc/monitoring-kube-prometheus-prometheus}"
APP_SERVICE="${APP_SERVICE:-bakery-bakery-orders-api}"
PORT="${PORT:-19090}"
BASE="http://127.0.0.1:$PORT"

kubectl -n monitoring port-forward "$PROM_SVC" "$PORT:9090" >/dev/null &
PF_PID=$!
trap 'kill $PF_PID' EXIT

# Prometheus needs time to discover the ServiceMonitor and do a first scrape (interval 15s).
for i in $(seq 1 40); do
  result=$(curl -fsS --get "$BASE/api/v1/query" --data-urlencode "query=up{service=\"$APP_SERVICE\"}" 2>/dev/null || true)
  if jq -e '.data.result | length > 0 and all(.value[1] == "1")' <<<"$result" >/dev/null 2>&1; then
    echo "Prometheus target for $APP_SERVICE is up"
    exit 0
  fi
  echo "waiting for target $APP_SERVICE to be up ($i/40)"
  sleep 5
done

echo "FAIL: Prometheus has no healthy target for $APP_SERVICE. Last response: ${result:-none}"
exit 1
