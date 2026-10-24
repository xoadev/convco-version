#!/usr/bin/env bash
# Runs src/install.sh and src/calculate.sh the way action.yml does, against throwaway git repositories with crafted
# commits, and checks their outputs: the same cases as test.yml, whose jobs run the action itself with `uses: ./`.
# It needs git, curl and the network (it downloads convco); no GitHub runner.
set -euo pipefail

SRC="$(cd "$(dirname "$0")/../../src" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# What a runner gives each step; install.sh keeps convco under RUNNER_TEMP.
export RUNNER_TEMP="$WORK/runner" GITHUB_PATH="$WORK/github-path"
mkdir -p "$RUNNER_TEMP"

# The user's git config (signing, hooks, default branch) must not change what the repositories look like.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@test.com GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@test.com

FAILURES=0
CASE=""

fail() {
  echo "FAIL: $CASE: $1"
  FAILURES=$((FAILURES + 1))
}

# install <convco-version> [<sha256>]: the action's install step; convco goes first on the PATH.
install() {
  : >"$GITHUB_PATH"
  GITHUB_OUTPUT="$WORK/install-output" CONVCO_VERSION="$1" CONVCO_SHA256="${2:-}" "$SRC/install.sh" >/dev/null || return
  PATH="$(cat "$GITHUB_PATH"):$PATH"
}

# start <name>: a new case in a new repository with one root commit, like a checkout with every tag deleted.
start() {
  CASE="$1"
  cd "$(mktemp -d "$WORK/repo.XXXXXX")"
  git init -q
  git commit -q --allow-empty -m "chore: initial commit"
}

commit() {
  git commit -q --allow-empty -m "$1"
}

# commit_file <path> <message>
commit_file() {
  mkdir -p "$(dirname "$1")"
  touch "$1"
  git add "$1"
  git commit -q -m "$2"
}

# calculate [NAME=value...]: the action's calculate step, with the inputs as its environment.
calculate() {
  OUTPUT="$WORK/output"
  : >"$OUTPUT"
  env GITHUB_OUTPUT="$OUTPUT" "$@" "$SRC/calculate.sh" >/dev/null 2>&1 || fail "calculate.sh exited with $?"
}

# expect <output> <value>
expect() {
  local actual
  actual="$(sed -n "s/^$1=//p" "$OUTPUT")"
  [ "$actual" = "$2" ] || fail "$1 is '$actual', expected '$2'"
}

# expect_changelog <text>
expect_changelog() {
  grep -qF "$1" "$OUTPUT" || fail "the changelog misses '$1'"
}

install 0.7.2

start "basic patch bump"
git tag v1.0.0
commit "fix: something broken"
calculate
expect current-version 1.0.0
expect next-version 1.0.1
expect has-changes true
expect bump-type patch
expect commits-since-last-release 1

start "basic minor bump"
git tag v1.0.0
commit "feat: add new feature"
calculate
expect current-version 1.0.0
expect next-version 1.1.0
expect bump-type minor

start "basic major bump"
git tag v1.0.0
commit "feat!: breaking change"
calculate
expect current-version 1.0.0
expect next-version 2.0.0
expect bump-type major

start "no changes"
git tag v1.0.0
calculate
expect current-version 1.0.0
expect next-version 1.0.0
expect has-changes false
expect bump-type none

start "bump type override"
git tag v1.0.0
commit "fix: minor fix"
calculate BUMP_TYPE=major
expect next-version 2.0.0
expect bump-type major

start "monorepo path filtering"
git tag v1.0.0
commit_file packages/core/file.js "feat(core): new feature"
commit_file packages/web/file.js "feat(web): web feature"
calculate PATHS=packages/core
expect has-changes true
expect bump-type minor

start "monorepo no changes in path"
git tag v1.0.0
commit_file packages/web/file.js "feat(web): web feature"
calculate PATHS=packages/core
expect has-changes false
expect bump-type none

start "monorepo path with spaces"
git tag v1.0.0
commit_file "packages/my core/file.js" "feat(core): new feature"
commit_file packages/web/file.js "fix(web): web fix"
calculate "PATHS=packages/web, packages/my core"
expect next-version 1.1.0
expect bump-type minor

start "custom tag prefix"
git tag release-1.0.0
commit "fix: something"
calculate TAG_PREFIX=release-
expect current-version-tag release-1.0.0
expect next-version-tag release-1.0.1

start "changelog generation"
git tag v1.0.0
commit "feat: add feature"
commit "fix: fix bug"
calculate
expect_changelog "add feature"
expect_changelog "fix bug"

start "no tags (0.0.0 -> 0.1.0)"
commit "feat: first feature"
calculate
expect current-version 0.0.0
expect next-version 0.1.0
expect has-changes true
expect bump-type minor

start "working directory with .versionrc"
git tag v1.0.0
mkdir -p packages/core
echo "preMajor: false" >packages/core/.versionrc
git add packages/core/.versionrc
commit_file packages/core/file.js "feat: new feature"
calculate WORKING_DIRECTORY=packages/core PATHS=packages/core
expect has-changes true
expect bump-type minor

CASE="convco 0.6 (zip releases)"
install 0.6.3
start "$CASE"
git tag v1.0.0
commit "fix: something broken"
calculate
expect next-version 1.0.1

# Last: a mismatching checksum also deletes the cached archive.
CASE="a download that doesn't match its checksum is refused"
if install 0.7.2 0000000000000000000000000000000000000000000000000000000000000000 2>/dev/null; then
  fail "install.sh accepted it"
fi
! compgen -G "$RUNNER_TEMP/convco-cache/convco-v0.7.2-*" >/dev/null || fail "the archive was kept"

CASE="a version without a known checksum is refused"
if install 0.7.1 2>/dev/null; then
  fail "install.sh accepted it"
fi

if [ "$FAILURES" -gt 0 ]; then
  echo "$FAILURES check(s) failed"
  exit 1
fi
echo "All checks passed"
