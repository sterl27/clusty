#!/usr/bin/env bash
# 03-nvidia-runtime.sh — wire the NVIDIA Container Toolkit into k3s's embedded
# containerd so GPU pods can use the 'nvidia' RuntimeClass.
#
# Run this INSIDE WSL2 after script 02-agent-wsl2.sh has completed and k3s-agent
# has started at least once (so its containerd config exists on disk).
set -euo pipefail

K3S_CTR_CFG=/var/lib/rancher/k3s/agent/etc/containerd/config.toml
K3S_CTR_TMPL="${K3S_CTR_CFG}.tmpl"

# ── 1. install NVIDIA Container Toolkit ───────────────────────────────────────
echo "==> Installing NVIDIA Container Toolkit..."
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -sL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

sudo apt-get update -qq
sudo apt-get install -y nvidia-container-toolkit

# ── 2. wait for k3s-agent to generate its containerd config ──────────────────
echo "==> Waiting for k3s agent containerd config..."
until sudo test -f "${K3S_CTR_CFG}"; do
  echo "    (not yet — is k3s-agent running? sudo systemctl status k3s-agent)"
  sleep 5
done
echo "    Found: ${K3S_CTR_CFG}"

# ── 3. stamp a .tmpl so k3s doesn't overwrite our changes on restart ──────────
sudo cp "${K3S_CTR_CFG}" "${K3S_CTR_TMPL}"
echo "==> Saved containerd config template: ${K3S_CTR_TMPL}"

# ── 4. inject the nvidia runtime into the template ────────────────────────────
sudo nvidia-ctk runtime configure \
  --runtime=containerd \
  --config="${K3S_CTR_TMPL}"
echo "==> NVIDIA runtime injected into containerd template"

# ── 5. restart k3s-agent to pick up the new runtime ──────────────────────────
if sudo systemctl is-active --quiet k3s-agent; then
  echo "==> Restarting k3s-agent..."
  sudo systemctl restart k3s-agent
  sleep 5
  sudo systemctl is-active k3s-agent && echo "    k3s-agent is running" \
    || echo "    WARNING: k3s-agent failed to start — check: sudo journalctl -u k3s-agent -n 50"
else
  echo "==> k3s-agent is not managed by systemd."
  echo "    Restart it manually, then re-run this script to verify."
fi

echo ""
echo "==> Verify with:"
echo "    sudo nvidia-ctk runtime configure --runtime=containerd --config=${K3S_CTR_TMPL} --dry-run 2>&1 | grep -i nvidia"
echo ""
echo "==> Next: run scripts/04-gpu-plugin.sh from a machine with kubeconfig."
