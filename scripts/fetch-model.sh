#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-$ROOT/.cache/models/SmolLM2-135M-Instruct-Q4_K_M.gguf}"
URL="${MODEL_URL:-https://huggingface.co/bartowski/SmolLM2-135M-Instruct-GGUF/resolve/main/SmolLM2-135M-Instruct-Q4_K_M.gguf}"

mkdir -p "$(dirname "$DEST")"
if [ -f "$DEST" ]; then
  echo "model exists: $DEST"
  exit 0
fi

curl -fL --retry 3 --connect-timeout 20 -o "$DEST.part" "$URL"
mv "$DEST.part" "$DEST"
echo "model ready: $DEST"
