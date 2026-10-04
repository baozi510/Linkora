#!/usr/bin/env bash
set -euo pipefail

ABI="${1:-}"
NATIVE_ROOT="${2:-${OHOS_NATIVE_ROOT:-}}"
SOURCE_ROOT="${3:-third_party/ffmpeg/source}"
OUT_ROOT="${4:-third_party/ffmpeg}"

if [[ -z "$ABI" || -z "$NATIVE_ROOT" ]]; then
  cat >&2 <<'EOF'
Usage:
  scripts/ffmpeg/build-harmony.sh <arm64-v8a|x86_64> <HarmonyOS-native-root> [source-root] [out-root]

The native root must contain:
  llvm/bin/clang
  llvm/bin/clang++
  llvm/bin/llvm-ar
  llvm/bin/llvm-ranlib
  llvm/bin/llvm-nm
  llvm/bin/llvm-strip
  sysroot/

Example:
  scripts/ffmpeg/build-harmony.sh x86_64 "$OHOS_NATIVE_ROOT"
EOF
  exit 2
fi

case "$ABI" in
  arm64-v8a)
    FF_ARCH="aarch64"
    TRIPLE="aarch64-linux-ohos"
    ;;
  x86_64)
    FF_ARCH="x86_64"
    TRIPLE="x86_64-linux-ohos"
    ;;
  *)
    echo "Unsupported ABI: $ABI" >&2
    exit 2
    ;;
esac

clang="$NATIVE_ROOT/llvm/bin/clang"
clangxx="$NATIVE_ROOT/llvm/bin/clang++"
ar="$NATIVE_ROOT/llvm/bin/llvm-ar"
ranlib="$NATIVE_ROOT/llvm/bin/llvm-ranlib"
nm="$NATIVE_ROOT/llvm/bin/llvm-nm"
strip="$NATIVE_ROOT/llvm/bin/llvm-strip"
sysroot="$NATIVE_ROOT/sysroot"

for tool in "$clang" "$clangxx" "$ar" "$ranlib" "$nm" "$strip"; do
  if [[ ! -x "$tool" && ! -f "${tool}.exe" ]]; then
    echo "HarmonyOS tool not found: $tool" >&2
    exit 1
  fi
done

if [[ ! -d "$sysroot" ]]; then
  echo "HarmonyOS sysroot not found: $sysroot" >&2
  exit 1
fi

if [[ ! -x "$SOURCE_ROOT/configure" ]]; then
  echo "FFmpeg source missing. Run scripts/ffmpeg/fetch-source.ps1 first." >&2
  exit 1
fi

BUILD_DIR="$OUT_ROOT/build/$ABI"
PREFIX="$OUT_ROOT/prebuilt/$ABI"
WRAPPER_DIR="$BUILD_DIR/toolchain-wrapper"

rm -rf "$BUILD_DIR" "$PREFIX"
mkdir -p "$WRAPPER_DIR" "$PREFIX"

cat > "$WRAPPER_DIR/cc" <<EOF
#!/usr/bin/env bash
exec "$clang" --target=$TRIPLE --sysroot="$sysroot" "\$@"
EOF

cat > "$WRAPPER_DIR/cxx" <<EOF
#!/usr/bin/env bash
exec "$clangxx" --target=$TRIPLE --sysroot="$sysroot" "\$@"
EOF

chmod +x "$WRAPPER_DIR/cc" "$WRAPPER_DIR/cxx"

ROOT_DIR="$(pwd)"
SOURCE_ABS="$ROOT_DIR/$SOURCE_ROOT"
PREFIX_ABS="$ROOT_DIR/$PREFIX"
CC_WRAPPER="$ROOT_DIR/$WRAPPER_DIR/cc"
CXX_WRAPPER="$ROOT_DIR/$WRAPPER_DIR/cxx"

pushd "$BUILD_DIR" >/dev/null

"$SOURCE_ABS/configure" \
  --prefix="$PREFIX_ABS" \
  --enable-cross-compile \
  --target-os=linux \
  --arch="$FF_ARCH" \
  --sysroot="$sysroot" \
  --cc="$CC_WRAPPER" \
  --cxx="$CXX_WRAPPER" \
  --ar="$ar" \
  --ranlib="$ranlib" \
  --nm="$nm" \
  --strip="$strip" \
  --enable-static \
  --disable-shared \
  --enable-pic \
  --disable-programs \
  --disable-doc \
  --disable-avdevice \
  --disable-avfilter \
  --disable-swresample \
  --disable-encoders \
  --disable-muxers \
  --disable-hwaccels \
  --disable-indevs \
  --disable-outdevs \
  --disable-autodetect \
  --disable-protocols \
  --enable-protocol=file \
  --enable-protocol=http \
  --enable-protocol=tcp \
  --enable-network \
  --extra-cflags="-fPIC" \
  --extra-ldflags="-Wl,--gc-sections"

make -j"${FFMPEG_JOBS:-4}"
make install

popd >/dev/null

for lib in avformat avcodec avutil swscale; do
  if [[ ! -f "$PREFIX/lib/lib${lib}.a" ]]; then
    echo "Missing expected FFmpeg static library: lib${lib}.a" >&2
    exit 1
  fi
done

cat > "$PREFIX/linkora-build-manifest.txt" <<EOF
ffmpeg_tag=n8.1.3
ffmpeg_commit=1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7
abi=$ABI
triple=$TRIPLE
target_os=linux
sysroot=$sysroot
libraries=avformat,avcodec,avutil,swscale
programs=disabled
encoders=disabled
muxers=disabled
hwaccels=disabled
EOF

echo "FFmpeg HarmonyOS bootstrap build completed:"
echo "  ABI: $ABI"
echo "  Prefix: $PREFIX"
