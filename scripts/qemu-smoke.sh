#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODEL="${MODEL:-$ROOT/.cache/models/SmolLM2-135M-Instruct-Q4_K_M.gguf}"

if [ ! -x "$ROOT/dist/llama-cli" ]; then
  echo "missing dist/llama-cli; run ./scripts/build-static.sh first" >&2
  exit 1
fi

docker run --rm --platform linux/arm64 \
  -v "$ROOT/dist:/dist:ro" \
  alpine:3.20 /dist/llama-cli --help >/dev/null

if [ -f "$MODEL" ]; then
  timeout 600 docker run --rm --platform linux/arm64 \
    -v "$ROOT/dist:/dist:ro" \
    -v "$(dirname "$MODEL"):/models:ro" \
    alpine:3.20 /dist/llama-cli \
    -m "/models/$(basename "$MODEL")" \
    -p "Hello" -n 1 -c 64 -t 1 -st --no-display-prompt
else
  echo "QEMU help smoke passed; no model at $MODEL (run ./scripts/fetch-model.sh)"
fi
