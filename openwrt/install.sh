#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
DESTDIR="${DESTDIR:-}"

[ -x "$ROOT/dist/llama-cli" ] || {
  echo "missing dist/llama-cli; build first" >&2
  exit 1
}

install -d "$DESTDIR/usr/bin" "$DESTDIR/root/models"
install -m755 "$ROOT/dist/llama-cli" "$DESTDIR/usr/bin/llama-cli"

cat <<'TXT'
installed: /usr/bin/llama-cli
next:
  1. copy a GGUF model to /root/models/
  2. run: llama-cli -m /root/models/model.gguf -p "Hello" -n 32 -c 256 -t 2
TXT
