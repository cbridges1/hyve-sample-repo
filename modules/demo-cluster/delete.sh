#!/bin/sh
set -e
MODULE_DIR="$(cd "$(dirname "$0")" && pwd)"
rm -f "$MODULE_DIR/.state/$HYVE_CLUSTER_NAME"
echo "HYVE_CLUSTER_STATUS=NOT_FOUND"
