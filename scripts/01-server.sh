#!/usr/bin/env bash
# 01-server.sh — install k3s control plane on the Ubuntu server node.
#
# Run this ON the server (192.168.0.28), either directly or via:
#   ssh ubuntu@192.168.0.28 'bash -s' < scripts/01-server.sh
set -euo pipefail

echo "==> Installing k3s server..."
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=stable sh -s - server \
  --write-kubeconfig-mode=644 \
  --node-label="node-role=server"

echo "==> Opening required firewall ports..."
if command -v ufw &>/dev/null; then
  sudo ufw allow 6443/tcp   comment "k3s API server"
  sudo ufw allow 8472/udp   comment "k3s Flannel VXLAN"
  sudo ufw allow 10250/tcp  comment "k3s kubelet metrics"
  sudo ufw allow 51820/udp  comment "k3s Wireguard"
  sudo ufw allow 51821/udp  comment "k3s Wireguard IPv6"
  sudo ufw reload
fi

echo "==> Waiting for k3s to be ready..."
until sudo k3s kubectl get nodes &>/dev/null; do sleep 2; done
sudo k3s kubectl get nodes

echo ""
echo "==> JOIN TOKEN (copy this for the agent install):"
sudo cat /var/lib/rancher/k3s/server/node-token

echo ""
echo "==> KUBECONFIG (copy to ~/.kube/config on your workstation):"
sudo cat /etc/rancher/k3s/k3s.yaml
