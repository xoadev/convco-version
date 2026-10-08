#!/usr/bin/env bash
set -euo pipefail

CONVCO_VERSION="${CONVCO_VERSION:-0.7.2}"
OS=$(uname -s)
ARCH=$(uname -m)
CACHE_DIR="${RUNNER_TEMP:-/tmp}/convco-cache"
BIN_DIR="${RUNNER_TEMP:-/tmp}/convco-bin"

# convco 0.6 published a zip per OS; from 0.7 on, a tar.gz per target.
case "$CONVCO_VERSION" in
  0.6.*)
    case "$OS/$ARCH" in
      Linux/x86_64) ASSET="convco-ubuntu.zip" ;;
      Linux/aarch64) ASSET="convco-ubuntu-aarch64.zip" ;;
      Darwin/*) ASSET="convco-macos.zip" ;;
      CYGWIN*/* | MINGW*/* | MSYS*/*) ASSET="convco-windows.zip" ;;
    esac
    ;;
  *)
    case "$OS/$ARCH" in
      Linux/x86_64) TARGET="x86_64-unknown-linux-musl" ;;
      Linux/aarch64) TARGET="aarch64-unknown-linux-musl" ;;
      Darwin/arm64) TARGET="aarch64-apple-darwin" ;;
      CYGWIN*/* | MINGW*/* | MSYS*/*) TARGET="x86_64-pc-windows-msvc" ;;
    esac
    [ -z "${TARGET:-}" ] || ASSET="convco-v${CONVCO_VERSION}-${TARGET}.tar.gz"
    ;;
esac
if [ -z "${ASSET:-}" ]; then
  echo "::error::convco $CONVCO_VERSION has no build for $OS $ARCH"
  exit 1
fi

# The sha256 of every release asset this action knows, as GitHub reports it for the convco release. A download is
# run only if it matches: a replaced asset, or a cache entry someone else wrote, is refused.
known_sha256() {
  case "$1" in
    0.7.2/convco-v0.7.2-x86_64-unknown-linux-musl.tar.gz) echo a34797bb6867d3444cce9466c96d49abea4cecd02cac12dce218b637570fd0d4 ;;
    0.7.2/convco-v0.7.2-aarch64-unknown-linux-musl.tar.gz) echo 8871a3b435703f076b759fc7dfaf35f70d039542fad8210437c457ceb4663863 ;;
    0.7.2/convco-v0.7.2-aarch64-apple-darwin.tar.gz) echo 410b58bd38db0d3402b8ef950234b44b800ae748148fa6d22ebdcfa6a330785f ;;
    0.7.2/convco-v0.7.2-x86_64-pc-windows-msvc.tar.gz) echo 57601b963de1b3a8ffff75041b76e2caa20d375305037ffe120f4fc423ece3e6 ;;
    0.6.3/convco-ubuntu.zip) echo 9c9998df44cebdace0813d12297685261ff91497e742d7afbb57f147b4bd81ec ;;
    0.6.3/convco-ubuntu-aarch64.zip) echo 9dacefc6b2fb005d6f3c806a0c7abe0f87e510d97af69f2e1835997bea54be2d ;;
    0.6.3/convco-macos.zip) echo 6cbe5984ca5d0c0c7fdac9419d8e7f060fb81d33c798e6ee84c211dbbf247e24 ;;
    0.6.3/convco-windows.zip) echo 4cdd9fc2292bf8038462db2873d8f5a67135486c98cb975d8bf373eb29315f13 ;;
  esac
}

EXPECTED="${CONVCO_SHA256:-$(known_sha256 "$CONVCO_VERSION/$ASSET")}"
if [ -z "$EXPECTED" ]; then
  echo "::error::No checksum known for convco $CONVCO_VERSION ($ASSET); give it with the convco-sha256 input"
  exit 1
fi

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d ' ' -f 1
}

if [[ "$ASSET" == *.zip ]] && ! command -v unzip >/dev/null 2>&1; then
  echo "::error::unzip is required but not installed"
  exit 1
fi

# The cache keeps the archive, never the binary: it is checked like a download on every run.
mkdir -p "$CACHE_DIR"
ARCHIVE="$CACHE_DIR/$ASSET"
if [ -f "$ARCHIVE" ] && [ "$(sha256 "$ARCHIVE")" = "$EXPECTED" ]; then
  echo "Using cached convco"
  echo "cache-hit=true" >>"$GITHUB_OUTPUT"
else
  echo "cache-hit=false" >>"$GITHUB_OUTPUT"
  URL="https://github.com/convco/convco/releases/download/v${CONVCO_VERSION}/${ASSET}"
  echo "Downloading convco from $URL"
  curl -fsSL --proto '=https' --retry 3 "$URL" -o "$ARCHIVE"
  ACTUAL=$(sha256 "$ARCHIVE")
  if [ "$ACTUAL" != "$EXPECTED" ]; then
    rm -f "$ARCHIVE"
    echo "::error::$ASSET has sha256 $ACTUAL, not $EXPECTED; refusing to run it"
    exit 1
  fi
fi

rm -rf "$BIN_DIR"
mkdir -p "$BIN_DIR"
if [[ "$ASSET" == *.zip ]]; then
  unzip -q -o "$ARCHIVE" -d "$BIN_DIR"
else
  tar -xzf "$ARCHIVE" -C "$BIN_DIR" --strip-components=1
fi
if [[ "$OS" =~ CYGWIN*|MINGW*|MSYS* ]]; then
  mv "$BIN_DIR/convco.exe" "$BIN_DIR/convco"
fi
chmod +x "$BIN_DIR/convco"
echo "$BIN_DIR" >>"$GITHUB_PATH"
