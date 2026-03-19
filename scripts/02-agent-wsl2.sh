#!/usr/bin/env bash
# 02-agent-wsl2.sh — join WSL2 (RTX 4070) to the cluster as a GPU agent node.
#
# Prerequisites:
#   - script 00-wslconfig.ps1 has been run (WSL2 uses mirrored networking)
#   - script 01-server.sh has been run on 192.168.0.28
#   - SSH access to the server: ssh ubuntu@192.168.0.28
#
# Run this INSIDE WSL2:
#   bash scripts/02-agent-wsl2.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../config.env
source "${SCRIPT_DIR}/../config.env"

# ── detect this node's LAN IP (should be 192.168.0.x after mirrored networking)
NODE_IP=$(ip route get "${SERVER_IP}" | grep -oP 'src \K\S+')
echo "==> WSL2 node IP: ${NODE_IP}"

if [[ "${NODE_IP}" == 172.* ]]; then
  echo ""
  echo "ERROR: WSL2 is still behind NAT (IP=${NODE_IP})."
  echo "Run scripts/00-wslconfig.ps1 from an elevated PowerShell first,"
  echo "then restart WSL and re-run this script."
  exit 1
fi

# ── fetch the join token from the server over SSH
echo "==> Fetching join token from ${SERVER_SSH_USER}@${SERVER_IP}..."
NODE_TOKEN=$(ssh -o StrictHostKeyChecking=accept-new \
  "${SERVER_SSH_USER}@${SERVER_IP}" \
  "sudo cat /var/lib/rancher/k3s/server/node-token")

# ── install k3s agent
echo "==> Installing k3s agent (GPU node)..."
curl -sfL https://get.k3s.io | \
  K3S_URL="https://${SERVER_IP}:6443" \
  K3S_TOKEN="${NODE_TOKEN}" \
  INSTALL_K3S_CHANNEL="${K3S_CHANNEL}" \
  sh -s - agent \
    --node-name="${GPU_NODE_NAME}" \
    --node-ip="${NODE_IP}" \
    --node-label="gpu=true" \
    --node-label="nvidia.com/gpu.present=true"

echo ""
echo "==> k3s agent installed. Check node status from the server:"
echo "    sudo k3s kubectl get nodes"
echo ""
echo "==> Next: run scripts/03-nvidia-runtime.sh to configure the NVIDIA container runtime."
