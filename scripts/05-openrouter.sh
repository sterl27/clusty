#!/usr/bin/env bash
# 05-openrouter.sh — Deploy Open WebUI configured for OpenRouter
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

source "${ROOT_DIR}/config.env"

if [[ ! -f "${ROOT_DIR}/.env" ]]; then
  echo "ERROR: .env not found at ${ROOT_DIR}/.env"
  echo "Create it from template and set OPENROUTER_API_KEY first."
  exit 1
fi

# shellcheck disable=SC1091
source "${ROOT_DIR}/.env"

if [[ -z "${OPENROUTER_API_KEY:-}" || "${OPENROUTER_API_KEY}" == "YOUR_OPENROUTER_API_KEY_HERE" ]]; then
  echo "ERROR: OPENROUTER_API_KEY is missing or still set to placeholder in .env"
  exit 1
fi

echo "==> Ensuring namespace ${NAMESPACE} exists..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "==> Creating/updating OpenRouter API secret..."
kubectl -n "${NAMESPACE}" create secret generic openrouter-api \
  --from-literal=OPENROUTER_API_KEY="${OPENROUTER_API_KEY}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "==> Applying Open WebUI deployment..."
kubectl apply -f "${ROOT_DIR}/manifests/openwebui-openrouter.yaml"

echo "==> Waiting for rollout..."
kubectl -n "${NAMESPACE}" rollout status deployment/open-webui --timeout=180s

echo ""
echo "OpenRouter UI deployed."
echo "Access it locally with: kubectl -n ${NAMESPACE} port-forward svc/open-webui 3000:80"
