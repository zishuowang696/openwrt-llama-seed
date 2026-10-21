# openwrt-llama-seed

A small, reproducible seed for running **llama.cpp on OpenWrt aarch64**.
It builds a static musl `llama-cli`, checks it under QEMU aarch64, and gives
you an install path for a router.

This is a **seed**, not an official OpenWrt package and not a promise that a
7B model fits on a router.

## What is inside

- `scripts/build-static.sh` — cross-compile `llama-cli` for `aarch64` musl,
  pinned to `LLAMA_CPP_REF` (default `v0.7.0`), no OpenMP, no shared libs.
- `scripts/fetch-model.sh` — download SmolLM2-135M-Instruct Q4_K_M (~100 MB).
- `scripts/qemu-smoke.sh` — run the binary under QEMU aarch64 user-mode.
- `openwrt/install.sh` — install `llama-cli` and create `/root/models`.
- `.github/workflows/ci.yml` — build + QEMU smoke; model smoke on `main`.

## Build

Requirements: Linux x86_64, `git`, `cmake`, `curl`, ~2 GB free disk.

```sh
./scripts/build-static.sh
```

Output:

```text
dist/llama-cli
```

The script downloads the `aarch64-linux-musl-cross` toolchain on first run and
caches it under `.toolchain/`. Set `LLAMA_CPP_REF` to pin another tag/commit.

Build `llama-server` too (optional, not covered by CI):

```sh
LLAMA_TARGETS="llama-cli llama-server" ./scripts/build-static.sh
```

## QEMU smoke

```sh
docker run --privileged --rm tonistiigi/binfmt --install arm64
./scripts/fetch-model.sh
./scripts/qemu-smoke.sh
```

The CI uses `docker/setup-qemu-action` and an `alpine:3.20` arm64 container.
It verifies the binary is aarch64 and runs `--help`; on `main` it also loads the
135M model and generates one token.

## Run on OpenWrt

```sh
scp dist/llama-cli root@router:/usr/bin/
scp .cache/models/SmolLM2-135M-Instruct-Q4_K_M.gguf root@router:/root/models/
ssh root@router
llama-cli -m /root/models/SmolLM2-135M-Instruct-Q4_K_M.gguf \
  -p "Explain what a router does." -n 32 -c 256 -t 2
```

## What it does not do

- No `opkg`/`apk` package; install is a file copy.
- No GPU, NPU, or 32-bit MIPS support.
- No model download at boot; keep models on `/overlay` or USB.
- No HTTP server by default.
- 135M is a proof of concept; it is not a useful general assistant.

## Hardware targets

- aarch64, musl, Linux kernel with normal socket/thread support.
- At least 512 MB free RAM for the 135M smoke; 1 GB is safer.
- ~150 MB free storage for binary + model.

## CI

The workflow is `.github/workflows/ci.yml`. It does not boot the OpenWrt kernel;
it validates the aarch64 userspace binary under QEMU. That is intentional: it
catches wrong architecture, shared-library links and immediate crashes without
maintaining a full OpenWrt VM in every PR.

## License

MIT. llama.cpp is MIT; see its upstream repository for model licenses.
