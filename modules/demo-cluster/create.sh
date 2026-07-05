#!/bin/sh
set -e
# Fully local fake "create" — writes a state marker instead of calling any
# real cloud API, so this module works offline with zero credentials.
MODULE_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$MODULE_DIR/.state"
mkdir -p "$STATE_DIR"
echo "${HYVE_PARAM_NODE_COUNT:-3}:${HYVE_PARAM_NODE_SIZE:-small}" > "$STATE_DIR/$HYVE_CLUSTER_NAME"

echo "HYVE_CLUSTER_STATUS=ACTIVE"
echo "HYVE_ENDPOINT=https://demo-cluster.local/$HYVE_CLUSTER_NAME"
echo "HYVE_NODE_COUNT=${HYVE_PARAM_NODE_COUNT:-3}"
