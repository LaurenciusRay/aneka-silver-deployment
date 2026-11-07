
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SERVICE="${1:-}"

case "$SERVICE" in
  api)
    IMAGE="aneka-silver-api"
    CONTAINER="aneka-api"
    HEALTH_URL="http://127.0.0.1:18080/ready"
    ;;
  web)
    IMAGE="aneka-silver-web"
    CONTAINER="aneka-web"
    HEALTH_URL="http://127.0.0.1:18081/"
    ;;
  *)
    echo "Usage: $0 api|web"
    exit 1
    ;;
esac

exec 9>.deploy.lock
flock -x 9

DOCKER=(sudo -n docker)
COMPOSE=(sudo -n docker compose)

echo "===== CHECK ROLLBACK IMAGE ====="

"${DOCKER[@]}" image inspect "$IMAGE:rollback" >/dev/null

echo "===== ROLLBACK $SERVICE ====="

# Temporarily override the image used by Compose.
OVERRIDE=$(mktemp "./.rollback-${SERVICE}.XXXXXX.yaml")
trap 'rm -f "$OVERRIDE"' EXIT

cat > "$OVERRIDE" <<EOF
services:
  $SERVICE:
    image: $IMAGE:rollback
    pull_policy: never
EOF

"${COMPOSE[@]}" \
  -f compose.yaml \
  -f "$OVERRIDE" \
  up -d --no-deps --no-build --force-recreate "$SERVICE"

echo "===== HEALTHCHECK ====="

for i in $(seq 1 12); do
  if "${DOCKER[@]}" inspect \
    -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null \
    | grep -qx true \
    && curl -fsS --max-time 5 \
      -o /dev/null "$HEALTH_URL"; then
    echo "Rollback successful: $SERVICE"
    exit 0
  fi

  sleep 5
done

echo "Rollback container is unhealthy"
exit 1
