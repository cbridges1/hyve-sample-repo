#!/bin/sh
set -e
MODULE_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_FILE="$MODULE_DIR/.state/$HYVE_CLUSTER_NAME"

if [ -f "$STATE_FILE" ]; then
  echo "HYVE_CLUSTER_STATUS=ACTIVE"
else
  echo "HYVE_CLUSTER_STATUS=NOT_FOUND"
fi
