#!/usr/bin/env bash
# 04-gpu-plugin.sh — apply the NVIDIA RuntimeClass and device plugin DaemonSet
# to the cluster, then verify the GPU is advertised as an allocatable resource.
#
# Run from WSL2 (or any host with kubeconfig pointing to the cluster).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="${SCRIPT_DIR}/../manifests"

# ── kubeconfig: prefer local, fall back to from the server ────────────────────
if [[ ! -f "${HOME}/.kube/config" ]]; then
  source "${SCRIPT_DIR}/../config.env"
  echo "==> No local kubeconfig — fetching from ${SERVER_SSH_USER}@${SERVER_IP}..."
  mkdir -p "${HOME}/.kube"
  ssh "${SERVER_SSH_USER}@${SERVER_IP}" "sudo cat /etc/rancher/k3s/k3s.yaml" \
    | sed "s/127.0.0.1/${SERVER_IP}/g" \
    > "${HOME}/.kube/config"
  chmod 600 "${HOME}/.kube/config"
  echo "    Saved to ~/.kube/config"
fi

echo "==> Applying NVIDIA RuntimeClass..."
kubectl apply -f "${MANIFESTS}/runtimeclass-nvidia.yaml"

echo "==> Applying NVIDIA device plugin DaemonSet..."
kubectl apply -f "${MANIFESTS}/nvidia-device-plugin.yaml"

echo "==> Waiting for device plugin to roll out (timeout 120s)..."
kubectl rollout status daemonset/nvidia-device-plugin-daemonset \
  -n kube-system --timeout=120s

echo ""
echo "==> Allocatable resources on gpu-node:"
kubectl get node gpu-node \
  -o jsonpath='{range .status.allocatable}{.k}{"\t"}{.v}{"\n"}{end}' 2>/dev/null \
  || kubectl get node gpu-node -o jsonpath='{.status.allocatable}' \
  | python3 -m json.tool

echo ""
echo "==> nvidia.com/gpu capacity:"
kubectl get node gpu-node \
  -o jsonpath='{.status.allocatable.nvidia\.com/gpu}' \
  && echo " GPU(s) allocatable" || echo "(device plugin may still be initializing — retry in 30s)"
