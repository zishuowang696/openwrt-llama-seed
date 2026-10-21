# OpenWrt integration

This seed ships a static `aarch64` musl binary. It does not need shared
libraries, but the model file does not belong in the firmware image.

## Install

```sh
DESTDIR=/ scp dist/llama-cli root@router:/usr/bin/llama-cli
ssh root@router 'mkdir -p /root/models'
scp model.gguf root@router:/root/models/
```

Or stage into a rootfs directory:

```sh
DESTDIR=/tmp/rootfs ./openwrt/install.sh
```

## Run

```sh
llama-cli -m /root/models/model.gguf \
  -p "Explain what a router does." \
  -n 32 -c 256 -t 2
```

On a 4-core router, `-t 2` or `-t 3` leaves a core for `netifd`/`dnsmasq`.
Keep `-c` small; KV cache is part of RAM usage.

## Limits

- `llama-cli` is one-shot, not a long-running HTTP service.
- Building `llama-server` is possible with `LLAMA_TARGETS="llama-cli llama-server"`,
  but this seed's CI only builds and runs `llama-cli`.
- Do not expose an unauthenticated inference endpoint on WAN.
- Static binary is Linux/aarch64; it does not support 32-bit MIPS routers.
