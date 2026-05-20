#!/usr/bin/env bash
set -euo pipefail

CONVCO_VERSION="${CONVCO_VERSION:-0.6.3}"
OS=$(uname -s)
ARCH=$(uname -m)
CACHE_DIR="${RUNNER_TEMP:-/tmp}/convco-cache"

mkdir -p "$CACHE_DIR"
echo "$CACHE_DIR" >> "$GITHUB_PATH"

if [ -f "$CACHE_DIR/convco" ] && [ "$(cat "$CACHE_DIR/.version" 2>/dev/null)" = "$CONVCO_VERSION" ]; then
  echo "Using cached convco"
  echo "cache-hit=true" >> "$GITHUB_OUTPUT"
  exit 0
fi

echo "cache-hit=false" >> "$GITHUB_OUTPUT"

if [ "$OS" = "Linux" ]; then
  if [ "$ARCH" = "x86_64" ]; then
    URL="https://github.com/convco/convco/releases/download/v${CONVCO_VERSION}/convco-ubuntu.zip"
  elif [ "$ARCH" = "aarch64" ]; then
    URL="https://github.com/convco/convco/releases/download/v${CONVCO_VERSION}/convco-ubuntu-aarch64.zip"
  else
    echo "::error::Unsupported architecture: $ARCH"
    exit 1
  fi
elif [ "$OS" = "Darwin" ]; then
  URL="https://github.com/convco/convco/releases/download/v${CONVCO_VERSION}/convco-macos.zip"
elif [[ "$OS" =~ CYGWIN*|MINGW*|MSYS* ]]; then
  URL="https://github.com/convco/convco/releases/download/v${CONVCO_VERSION}/convco-windows.zip"
else
  echo "::error::Unsupported OS: $OS"
  exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
  echo "::error::unzip is required but not installed"
  exit 1
fi

echo "Downloading convco from $URL"
curl -sL "$URL" -o "$CACHE_DIR/convco.zip"
unzip -o "$CACHE_DIR/convco.zip" -d "$CACHE_DIR"

if [[ "$OS" =~ CYGWIN*|MINGW*|MSYS* ]]; then
  mv "$CACHE_DIR/convco.exe" "$CACHE_DIR/convco"
fi

chmod +x "$CACHE_DIR/convco"
echo "$CONVCO_VERSION" > "$CACHE_DIR/.version"
rm -f "$CACHE_DIR/convco.zip"
