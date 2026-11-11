#!/usr/bin/env bash
# Build the bakery-orders-api image from source and load it into the kind cluster.
# Building locally means the lab works even without a published GHCR tag.
#
# Usage: scripts/load-image.sh            # clones b0tjim/bakery-orders-api into .cache/
#        APP_SRC=../bakery-orders-api scripts/load-image.sh   # use an existing checkout
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-bakery-lab}"
IMAGE="${IMAGE:-bakery-orders-api:local}"
APP_REPO="${APP_REPO:-https://github.com/b0tjim/bakery-orders-api.git}"
APP_REF="${APP_REF:-main}"
APP_SRC="${APP_SRC:-}"

if [[ -z "$APP_SRC" ]]; then
  APP_SRC=".cache/bakery-orders-api"
  if [[ -d "$APP_SRC/.git" ]]; then
    git -C "$APP_SRC" fetch --depth 1 origin "$APP_REF"
    git -C "$APP_SRC" checkout -q FETCH_HEAD
  else
    git clone --depth 1 --branch "$APP_REF" "$APP_REPO" "$APP_SRC"
  fi
fi

echo "Building $IMAGE from $APP_SRC"
docker build -t "$IMAGE" "$APP_SRC"

if [[ "${SKIP_KIND_LOAD:-}" == "1" ]]; then
  echo "SKIP_KIND_LOAD=1, not loading into kind"
  exit 0
fi

echo "Loading $IMAGE into kind cluster $CLUSTER_NAME"
kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"
