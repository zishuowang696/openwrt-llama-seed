#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REF="${LLAMA_CPP_REF:-v0.7.0}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
TOOLCHAIN="${AARCH64_MUSL_TOOLCHAIN:-$ROOT/.toolchain/aarch64-linux-musl-cross}"
SRC="$ROOT/.build/llama.cpp"
BUILD="$ROOT/.build/aarch64"
DIST="$ROOT/dist"
TARGETS="${LLAMA_TARGETS:-llama-cli}"

if [ ! -x "$TOOLCHAIN/bin/aarch64-linux-musl-gcc" ]; then
  mkdir -p "$ROOT/.toolchain"
  rm -rf "$TOOLCHAIN"
  TOOLCHAIN_URL="${AARCH64_MUSL_TOOLCHAIN_URL:-https://github.com/biancheng-net/aarch64-linux-musl-cross/releases/download/v1.0/aarch64-linux-musl-cross.tgz}"
  curl -fL --retry 3 --connect-timeout 20 \
    "$TOOLCHAIN_URL" \
    -o "$ROOT/.toolchain/toolchain.tgz"
  tar -xzf "$ROOT/.toolchain/toolchain.tgz" -C "$ROOT/.toolchain"
  rm -f "$ROOT/.toolchain/toolchain.tgz"
fi

mkdir -p "$ROOT/.build"
if [ ! -d "$SRC/.git" ]; then
  git clone --depth 1 --branch "$REF" https://github.com/ggml-org/llama.cpp.git "$SRC"
else
  git -C "$SRC" fetch --depth 1 origin "$REF"
  git -C "$SRC" checkout --detach FETCH_HEAD
fi

cmake -S "$SRC" -B "$BUILD" \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DCMAKE_C_COMPILER="$TOOLCHAIN/bin/aarch64-linux-musl-gcc" \
  -DCMAKE_CXX_COMPILER="$TOOLCHAIN/bin/aarch64-linux-musl-g++" \
  -DCMAKE_AR="$TOOLCHAIN/bin/aarch64-linux-musl-ar" \
  -DCMAKE_RANLIB="$TOOLCHAIN/bin/aarch64-linux-musl-ranlib" \
  -DCMAKE_STRIP="$TOOLCHAIN/bin/aarch64-linux-musl-strip" \
  -DCMAKE_FIND_ROOT_PATH="$TOOLCHAIN/aarch64-linux-musl" \
  -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
  -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
  -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
  -DCMAKE_C_FLAGS="-O3 -march=armv8-a -mtune=cortex-a53" \
  -DCMAKE_CXX_FLAGS="-O3 -march=armv8-a -mtune=cortex-a53" \
  -DCMAKE_EXE_LINKER_FLAGS="-static" \
  -DBUILD_SHARED_LIBS=OFF \
  -DGGML_OPENMP=OFF \
  -DGGML_NATIVE=OFF \
  -DGGML_BACKEND_DL=OFF \
  -DLLAMA_OPENSSL=OFF \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_SERVER=ON \
  -DLLAMA_BUILD_UI=OFF \
  -DLLAMA_USE_PREBUILT_UI=OFF

cmake --build "$BUILD" --target $TARGETS -j"$JOBS"

mkdir -p "$DIST"
for target in $TARGETS; do
  cp "$BUILD/bin/$target" "$DIST/$target"
  "$TOOLCHAIN/bin/aarch64-linux-musl-strip" "$DIST/$target"
done

file "$DIST"/*
sha256sum "$DIST"/*
