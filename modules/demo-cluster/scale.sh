#!/bin/sh
set -e
MODULE_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_FILE="$MODULE_DIR/.state/$HYVE_CLUSTER_NAME"
if [ -f "$STATE_FILE" ]; then
  echo "${HYVE_PARAM_NODE_COUNT:-3}:${HYVE_PARAM_NODE_SIZE:-small}" > "$STATE_FILE"
fi
echo "HYVE_NODE_COUNT=${HYVE_PARAM_NODE_COUNT:-3}"
