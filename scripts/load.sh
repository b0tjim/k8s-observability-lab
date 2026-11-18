#!/usr/bin/env bash
# Generate a little traffic so the Grafana dashboard has something to show.
# Mixes order creates, list/get reads, health checks and a few 404s.
#
# Usage: scripts/load.sh [requests]   (default 300, after `make install`)
set -euo pipefail

REQUESTS="${1:-300}"
SERVICE="${SERVICE:-svc/bakery-bakery-orders-api}"
PORT="${PORT:-18001}"
BASE="http://127.0.0.1:$PORT"
PIES=("apple pie" "pecan pie" "sweet potato pie" "peach cobbler")

kubectl port-forward "$SERVICE" "$PORT:8000" >/dev/null &
PF_PID=$!
trap 'kill $PF_PID' EXIT

for _ in $(seq 1 30); do
  curl -fsS "$BASE/health" >/dev/null 2>&1 && break
  sleep 1
done

for i in $(seq 1 "$REQUESTS"); do
  case $((RANDOM % 10)) in
    0 | 1 | 2)
      pie="${PIES[RANDOM % ${#PIES[@]}]}"
      curl -sS -o /dev/null -X POST "$BASE/orders" -H 'Content-Type: application/json' \
        -d "{\"customer_name\": \"load-$i\", \"items\": [{\"product\": \"$pie\", \"quantity\": $((RANDOM % 3 + 1)), \"unit_price\": \"18.00\"}]}" ;;
    3 | 4 | 5) curl -sS -o /dev/null "$BASE/orders" ;;
    6 | 7) curl -sS -o /dev/null "$BASE/orders/$((RANDOM % 20 + 1))" ;;  # some of these 404
    8) curl -sS -o /dev/null "$BASE/health" ;;
    9) curl -sS -o /dev/null "$BASE/orders/not-a-number" ;;            # 422
  esac
  sleep 0.1
done

echo "Sent $REQUESTS requests to $BASE"
