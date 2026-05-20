#!/usr/bin/env bash
set -euo pipefail

TAG_PREFIX="${TAG_PREFIX:-v}"
PATHS="${PATHS:-.}"
BUMP_INPUT="${BUMP_TYPE:-}"
WORK_DIR="${WORKING_DIRECTORY:-}"
INITIAL_VERSION="${INITIAL_VERSION:-}"

CONVCO_ARGS=""

if [ -n "$WORK_DIR" ]; then
  CONVCO_ARGS="$CONVCO_ARGS -C $WORK_DIR"
fi

IFS=',' read -ra PATH_LIST <<< "$PATHS"
for p in "${PATH_LIST[@]}"; do
  p=$(echo "$p" | xargs)
  if [ -n "$p" ] && [ "$p" != "." ]; then
    CONVCO_ARGS="$CONVCO_ARGS -P $p"
  fi
done

COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo "0")
if [ "$COMMIT_COUNT" -lt 2 ]; then
  echo "::warning::Shallow clone detected. Consider using 'fetch-depth: 0' with actions/checkout for accurate version calculation."
fi

CONFIG_ENTRIES=()

if [ -n "$INITIAL_VERSION" ]; then
  CONFIG_ENTRIES+=("initial_bump_version: \"$INITIAL_VERSION\"")
fi

if [ "$TAG_PREFIX" != "v" ]; then
  CONFIG_ENTRIES+=("tag_prefix: \"$TAG_PREFIX\"")
fi

if [ ${#CONFIG_ENTRIES[@]} -gt 0 ]; then
  CONFIG_FILE=".convco-temp"
  : > "$CONFIG_FILE"
  for entry in "${CONFIG_ENTRIES[@]}"; do
    printf '%s\n' "$entry" >> "$CONFIG_FILE"
  done
  CONVCO_ARGS="$CONVCO_ARGS -c $CONFIG_FILE"
fi

BUMP_OVERRIDE=""
case "$BUMP_INPUT" in
  major) BUMP_OVERRIDE="--major" ;;
  minor) BUMP_OVERRIDE="--minor" ;;
  patch) BUMP_OVERRIDE="--patch" ;;
  "") ;;
  *)
    echo "::error::Invalid bump-type '$BUMP_INPUT'. Must be one of: major, minor, patch"
    exit 1
    ;;
esac

CURRENT_VERSION=$(convco version $CONVCO_ARGS || echo "0.0.0")

if [ "$CURRENT_VERSION" = "0.0.0" ] && [ -z "$INITIAL_VERSION" ]; then
  echo "::warning::No version tags found. Set 'initial-version' input to specify a starting version."
fi

if [ -n "$BUMP_OVERRIDE" ]; then
  NEXT_VERSION=$(convco version $CONVCO_ARGS -b $BUMP_OVERRIDE 2>/dev/null || echo "$CURRENT_VERSION")
else
  NEXT_VERSION=$(convco version $CONVCO_ARGS -b 2>/dev/null || echo "$CURRENT_VERSION")
fi
DETECTED_BUMP=$(convco version $CONVCO_ARGS -b --label 2>/dev/null || echo "none")

if [ -n "$BUMP_OVERRIDE" ]; then
  DETECTED_BUMP="$BUMP_INPUT"
fi

CHANGELOG=$(convco changelog $CONVCO_ARGS -m 1 2>/dev/null | tail -n +5)

if [ "$CURRENT_VERSION" = "$NEXT_VERSION" ]; then
  HAS_CHANGES="false"
  FINAL_BUMP="none"
else
  HAS_CHANGES="true"
  FINAL_BUMP="$DETECTED_BUMP"
fi

LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
  COMMITS_SINCE=$(git rev-list "${LAST_TAG}..HEAD" --count 2>/dev/null || echo "0")
else
  COMMITS_SINCE=$(git rev-list --count HEAD 2>/dev/null || echo "0")
fi

echo "current-version=$CURRENT_VERSION" >> "$GITHUB_OUTPUT"
echo "current-version-tag=${TAG_PREFIX}${CURRENT_VERSION}" >> "$GITHUB_OUTPUT"
echo "next-version=$NEXT_VERSION" >> "$GITHUB_OUTPUT"
echo "next-version-tag=${TAG_PREFIX}${NEXT_VERSION}" >> "$GITHUB_OUTPUT"
echo "has-changes=$HAS_CHANGES" >> "$GITHUB_OUTPUT"
echo "bump-type=$FINAL_BUMP" >> "$GITHUB_OUTPUT"
echo "commits-since-last-release=$COMMITS_SINCE" >> "$GITHUB_OUTPUT"

{
  echo "changelog<<CHANGELOG_EOF"
  echo "$CHANGELOG"
  echo "CHANGELOG_EOF"
} >> "$GITHUB_OUTPUT"

echo "Current version: ${TAG_PREFIX}${CURRENT_VERSION}"
echo "Next version: ${TAG_PREFIX}${NEXT_VERSION}"
echo "Bump type: $FINAL_BUMP"
echo "Has changes: $HAS_CHANGES"
echo "Commits since last release: $COMMITS_SINCE"
