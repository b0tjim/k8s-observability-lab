#!/usr/bin/env bash
# Smoke-test the deployed app: port-forward the Service, check /health, create an order, list it back.
#
# Usage: scripts/smoke-test.sh   (after `make install`)
set -euo pipefail

SERVICE="${SERVICE:-svc/bakery-bakery-orders-api}"
PORT="${PORT:-18000}"
BASE="http://127.0.0.1:$PORT"

kubectl port-forward "$SERVICE" "$PORT:8000" >/dev/null &
PF_PID=$!
trap 'kill $PF_PID' EXIT

# Wait for the port-forward to start answering.
for _ in $(seq 1 30); do
  curl -fsS "$BASE/health" >/dev/null 2>&1 && break
  sleep 1
done

echo "GET /health"
curl -fsS "$BASE/health"; echo

echo "POST /orders"
curl -fsS -X POST "$BASE/orders" -H 'Content-Type: application/json' \
  -d '{"customer_name": "smoke-test", "items": [{"product": "apple pie", "quantity": 1, "unit_price": "18.00"}]}'
echo

echo "GET /orders"
orders=$(curl -fsS "$BASE/orders")
echo "$orders"
grep -q '"customer_name":"smoke-test"' <<<"$orders" || { echo "FAIL: created order not listed"; exit 1; }

echo "Smoke test passed"
