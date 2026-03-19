# clusty — k3s GPU cluster setup
#
# All targets that run shell commands must be executed from within WSL2.
# Targets prefixed with 'win-' are PowerShell commands for Windows.
#
# Quick start order:
#   1. make win-wslconfig        (PowerShell, once — enables mirrored networking)
#   2. make server               (from WSL2 — installs k3s on 192.168.0.28 via SSH)
#   3. make agent                (from WSL2 — joins WSL2 to the cluster)
#   4. make nvidia-runtime       (from WSL2 — configures NVIDIA containerd runtime)
#   5. make gpu-plugin           (from WSL2 — deploys device plugin)
#   6. make status               (from WSL2 — cluster and GPU health check)

SHELL       := /usr/bin/env bash
SCRIPT_DIR  := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))scripts
CONFIG      := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))config.env

# Load config values for targets that need them
-include $(CONFIG)


.PHONY: all win-wslconfig server agent nvidia-runtime gpu-plugin openrouter dashboard \
	kubeconfig status gpu-test clean help

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*##"}{printf "  %-18s %s\n",$$1,$$2}'

# ── Step 0: Windows networking ───────────────────────────────────────────────
win-wslconfig:  ## [PowerShell] Copy .wslconfig, restart WSL2 with mirrored networking
	@echo "Run this from an elevated PowerShell:"
	@echo "  powershell -ExecutionPolicy Bypass -File $(SCRIPT_DIR)/00-wslconfig.ps1"

# ── Step 1: k3s server on 192.168.0.28 ───────────────────────────────────────
server:  ## Install k3s server on SERVER_IP (via SSH)
	ssh -t $(SERVER_SSH_USER)@$(SERVER_IP) 'bash -s' < $(SCRIPT_DIR)/01-server.sh

# ── Step 2: k3s agent in WSL2 ────────────────────────────────────────────────
agent:  ## Join WSL2 GPU node to the cluster
	bash $(SCRIPT_DIR)/02-agent-wsl2.sh

# ── Step 3: NVIDIA container runtime ─────────────────────────────────────────
nvidia-runtime:  ## Install NVIDIA Container Toolkit and configure k3s containerd
	bash $(SCRIPT_DIR)/03-nvidia-runtime.sh

# ── Step 4: NVIDIA device plugin ─────────────────────────────────────────────
gpu-plugin: kubeconfig  ## Deploy NVIDIA RuntimeClass + device plugin DaemonSet
	bash $(SCRIPT_DIR)/04-gpu-plugin.sh

# ── Step 5: OpenRouter-backed UI ─────────────────────────────────────────────
openrouter: kubeconfig  ## Deploy Open WebUI configured to use OpenRouter API
	bash $(SCRIPT_DIR)/05-openrouter.sh

# ── Local Mission Control dashboard ──────────────────────────────────────────
dashboard:  ## Serve Mission Control dashboard at http://localhost:8088/dashboard/
	python3 -m http.server 8088

# ── kubeconfig helper ─────────────────────────────────────────────────────────
kubeconfig:  ## Fetch kubeconfig from server (writes to ~/.kube/config)
	@if [[ ! -f $(HOME)/.kube/config ]]; then \
	  mkdir -p $(HOME)/.kube; \
	  ssh $(SERVER_SSH_USER)@$(SERVER_IP) "sudo cat /etc/rancher/k3s/k3s.yaml" \
	    | sed "s/127.0.0.1/$(SERVER_IP)/g" > $(HOME)/.kube/config; \
	  chmod 600 $(HOME)/.kube/config; \
	  echo "Wrote $(HOME)/.kube/config"; \
	else \
	  echo "$(HOME)/.kube/config already exists — skipped"; \
	fi

# ── Status / health check ─────────────────────────────────────────────────────
status: kubeconfig  ## Show cluster nodes and GPU resource status
	@echo "━━ Nodes ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	kubectl get nodes -o wide
	@echo ""
	@echo "━━ GPU allocatable ━━━━━━━━━━━━━━━━━━━━━━"
	kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.allocatable.nvidia\.com/gpu}{"\n"}{end}'
	@echo ""
	@echo "━━ Device plugin pods ━━━━━━━━━━━━━━━━━━━"
	kubectl get pods -n kube-system -l name=nvidia-device-plugin-ds -o wide
	@echo ""
	@echo "━━ System pods ━━━━━━━━━━━━━━━━━━━━━━━━━━"
	kubectl get pods -n kube-system -o wide

# ── GPU smoke test ────────────────────────────────────────────────────────────
gpu-test: kubeconfig  ## Run a one-shot nvidia-smi pod to confirm GPU access
	kubectl run gpu-test --rm -it --restart=Never \
	  --image=nvcr.io/nvidia/cuda:12.3.0-base-ubuntu22.04 \
	  --overrides='{"spec":{"runtimeClassName":"nvidia","nodeSelector":{"gpu":"true"}}}' \
	  -- nvidia-smi

# ── Teardown ──────────────────────────────────────────────────────────────────
clean:  ## Remove NVIDIA manifests from the cluster (does not uninstall k3s)
	kubectl delete -f manifests/nvidia-device-plugin.yaml --ignore-not-found
	kubectl delete -f manifests/runtimeclass-nvidia.yaml  --ignore-not-found
	kubectl delete -f manifests/openwebui-openrouter.yaml  --ignore-not-found
	kubectl -n $(NAMESPACE) delete secret openrouter-api --ignore-not-found
