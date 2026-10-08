#!/usr/bin/env bash
# Checks that every example in the README uses this action at the given version, e.g. v1.1.0: a release would
# otherwise publish a README, also shown on the Marketplace, that points at an older version.
set -euo pipefail

EXPECTED="$1"
README="${2:-README.md}"
ACTION="xoadev/convco-version"

FAILED=0
FOUND=0
while IFS=: read -r LINE REF; do
  FOUND=$((FOUND + 1))
  # `@<sha> # vX.Y.Z` documents pinning by SHA: its comment is the version.
  VERSION="${REF#"$ACTION"@}"
  VERSION="${VERSION#<sha> # }"
  if [ "$VERSION" != "$EXPECTED" ]; then
    echo "::error file=$README,line=$LINE::$REF should use $EXPECTED, the version this change releases"
    FAILED=1
  fi
done < <(grep -noE "$ACTION@(<sha> # )?[^ \`)]+" "$README")

if [ "$FOUND" -eq 0 ]; then
  echo "::error file=$README::No example uses $ACTION"
  exit 1
fi
if [ "$FAILED" -ne 0 ]; then
  exit 1
fi
echo "All $FOUND examples in $README use $EXPECTED"
