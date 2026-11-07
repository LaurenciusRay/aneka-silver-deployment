
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SERVICE="${1:-}"

case "$SERVICE" in
  api)
    CONTAINER="aneka-api"
    IMAGE="aneka-silver-api"
    HEALTH_URL="http://127.0.0.1:18080/ready"
    ;;
  web)
    CONTAINER="aneka-web"
    IMAGE="aneka-silver-web"
    HEALTH_URL="http://127.0.0.1:18081/"
    ;;
  *)
    echo "Usage: $0 api|web"
    exit 1
    ;;
esac

# Prevent simultaneous deployments and rollbacks
exec 9>.deploy.lock
flock -x 9

DOCKER=(sudo -n docker)
COMPOSE=(sudo -n docker compose)

echo "===== SAVE CURRENT IMAGE ====="

if "${DOCKER[@]}" container inspect "$CONTAINER" >/dev/null 2>&1; then
  CURRENT_ID=$(
    "${DOCKER[@]}" inspect -f '{{.Image}}' "$CONTAINER"
  )

  if "${DOCKER[@]}" image inspect "$CURRENT_ID" >/dev/null 2>&1; then
    "${DOCKER[@]}" tag "$CURRENT_ID" "$IMAGE:rollback"
  else
    # Fallback if the old image was already removed
    "${DOCKER[@]}" commit "$CONTAINER" "$IMAGE:rollback"
  fi

  echo "Rollback image saved: $IMAGE:rollback"
else
  echo "No existing container; skipping rollback snapshot"
fi

echo "===== DEPLOY $SERVICE ====="

"${COMPOSE[@]}" up -d --no-deps --build "$SERVICE"

echo "===== HEALTHCHECK ====="

for i in $(seq 1 12); do
  if "${DOCKER[@]}" inspect \
    -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null \
    | grep -qx true \
    && curl -fsS --max-time 5 \
      -o /dev/null "$HEALTH_URL"; then
    echo "Deployment successful: $SERVICE"
    exit 0
  fi

  sleep 5
done

echo "Deployment unhealthy: $SERVICE"
echo "Previous image remains available for manual rollback"
"${COMPOSE[@]}" ps "$SERVICE"
exit 1
