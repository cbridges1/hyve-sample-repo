#!/bin/sh
set -e
echo "demo-cluster has no real API server to authenticate into." >&2
echo "A real module (e.g. hyve-modules/civo, hyve-modules/aws-eks) would run" >&2
echo "something like 'civo kubernetes config <name> --save' or" >&2
echo "'aws eks update-kubeconfig --name <name>' here to merge a working" >&2
echo "context into ~/.kube/config. This demo module has nothing real for" >&2
echo "kubectl to point at." >&2
