# convco-version

[![CI](https://github.com/xoadev/convco-version/actions/workflows/ci.yml/badge.svg)](https://github.com/xoadev/convco-version/actions/workflows/ci.yml)
[![Integration Tests](https://github.com/xoadev/convco-version/actions/workflows/test.yml/badge.svg)](https://github.com/xoadev/convco-version/actions/workflows/test.yml)
[![Release](https://img.shields.io/github/v/release/xoadev/convco-version?sort=semver)](https://github.com/xoadev/convco-version/releases)
[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-convco--version-blue.svg?logo=github)](https://github.com/marketplace/actions/convco-version)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-fe5196.svg)](https://www.conventionalcommits.org/)

A GitHub Action that works out the **current version, the next version, the bump type and the changelog** of your
project from its [Conventional Commits](https://www.conventionalcommits.org/), using
[convco](https://github.com/convco/convco).

Tag your releases, write `feat:` and `fix:` commits, and let the action tell you what comes next: no version files to
keep in sync, no Docker image to build, and the same answer on Linux, macOS and Windows.

Available on the [GitHub Marketplace](https://github.com/marketplace/actions/convco-version).

## Contents

- [Features](#features)
- [Quick start](#quick-start)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Usage](#usage)
- [Monorepo](#monorepo)
- [Configuration](#configuration)
- [How it works](#how-it-works)
- [Security](#security)
- [Requirements](#requirements)
- [Contributing](#contributing)
- [License](#license)

## Features

- Calculate current and next semantic version from git history
- Generate changelog for the next release
- Detect bump type (major, minor, patch)
- Detect if there are unreleased changes
- Monorepo support via path filtering and per-package `.versionrc`
- Force bump type override
- Fast execution with GitHub Actions caching (no Docker build overhead)
- convco checked against its sha256 before it runs, downloaded or from the cache
- Cross-platform: Linux, macOS, Windows

## Quick start

```yaml
- uses: actions/checkout@v7.0.1
  with:
    fetch-depth: 0

- uses: xoadev/convco-version@v1.1.0
  id: version

- run: echo "Next version is ${{ steps.version.outputs.next-version }}"
```

## Inputs

| Input | Description | Default |
| --- | --- | --- |
| `tag-prefix` | Prefix for version tags | `v` |
| `paths` | Comma-separated paths to filter commits (monorepo support) | `.` |
| `convco-version` | Version of convco to install | `0.7.2` |
| `convco-sha256` | sha256 of the convco release asset, for a `convco-version` whose checksum the action doesn't know | _(known versions)_ |
| `bump-type` | Force bump type: `major`, `minor`, or `patch` | _(auto-detect)_ |
| `working-directory` | Run convco from this path (useful for per-package `.versionrc`) | _(root)_ |

## Outputs

| Output | Description |
| --- | --- |
| `current-version` | Current version (e.g., `1.2.3`) |
| `current-version-tag` | Current version with prefix (e.g., `v1.2.3`) |
| `next-version` | Next version (e.g., `1.3.0`) |
| `next-version-tag` | Next version with prefix (e.g., `v1.3.0`) |
| `changelog` | Changelog for the next release |
| `has-changes` | `true` if there are unreleased commits |
| `bump-type` | Detected bump type: `major`, `minor`, `patch`, or `none` |
| `commits-since-last-release` | Number of commits since the last version tag |
| `cache-hit` | `true` if convco's archive came from the cache |

## Usage

### Draft a release on every push

```yaml
name: Release
on:
  push:
    branches: [main]

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7.0.1
        with:
          fetch-depth: 0

      - uses: xoadev/convco-version@v1.1.0
        id: version

      - name: Create Release
        if: steps.version.outputs.has-changes == 'true'
        uses: softprops/action-gh-release@v3.0.3
        with:
          tag_name: ${{ steps.version.outputs.next-version-tag }}
          name: Release ${{ steps.version.outputs.next-version }}
          body: ${{ steps.version.outputs.changelog }}
          draft: true
```

### Build artifact with version

```yaml
name: Build
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7.0.1
        with:
          fetch-depth: 0

      - uses: xoadev/convco-version@v1.1.0
        id: version

      - name: Build
        run: |
          echo "Building version $VERSION"
          # docker build -t "myapp:$VERSION" .
        env:
          VERSION: ${{ steps.version.outputs.next-version }}
```

### Force bump type

```yaml
- uses: xoadev/convco-version@v1.1.0
  id: version
  with:
    bump-type: major  # Force a major release regardless of commits
```

### Conditional release based on bump type

```yaml
- name: Create Major Release
  if: steps.version.outputs.bump-type == 'major'
  uses: softprops/action-gh-release@v3.0.3
  with:
    tag_name: ${{ steps.version.outputs.next-version-tag }}
    name: Major Release ${{ steps.version.outputs.next-version }}
    body: ${{ steps.version.outputs.changelog }}
```

## Monorepo

The `paths` input filters commits that affect specific directories. This is essential for monorepos where each package
maintains its own version.

### How path filtering works

Convco analyzes commits that touch the specified paths. Only commits modifying files within those paths are considered
when calculating the next version.

### Single package

```yaml
# packages/core/package.json
- uses: xoadev/convco-version@v1.1.0
  with:
    paths: 'packages/core'
```

Only commits touching `packages/core/**` will affect the version.

### Multiple packages

```yaml
# packages/web and packages/shared
- uses: xoadev/convco-version@v1.1.0
  with:
    paths: 'packages/web,packages/shared'
```

Commits touching either path are considered together.

### Per-package .versionrc

Use `working-directory` to run convco from a subdirectory that has its own `.versionrc`:

```yaml
- uses: xoadev/convco-version@v1.1.0
  with:
    working-directory: 'packages/core'
    paths: 'packages/core'
```

### Full workflow with matrix

```yaml
name: Release Packages
on:
  push:
    branches: [main]

permissions:
  contents: write

jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      core: ${{ steps.filter.outputs.core }}
      web: ${{ steps.filter.outputs.web }}
    steps:
      - uses: dorny/paths-filter@v4.0.3
        id: filter
        with:
          filters: |
            core:
              - 'packages/core/**'
            web:
              - 'packages/web/**'

  release-core:
    needs: changes
    if: needs.changes.outputs.core == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7.0.1
        with:
          fetch-depth: 0

      - uses: xoadev/convco-version@v1.1.0
        id: version
        with:
          paths: 'packages/core'

      - uses: softprops/action-gh-release@v3.0.3
        with:
          tag_name: core-${{ steps.version.outputs.next-version-tag }}
          body: ${{ steps.version.outputs.changelog }}
          draft: true

  release-web:
    needs: changes
    if: needs.changes.outputs.web == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7.0.1
        with:
          fetch-depth: 0

      - uses: xoadev/convco-version@v1.1.0
        id: version
        with:
          paths: 'packages/web'

      - uses: softprops/action-gh-release@v3.0.3
        with:
          tag_name: web-${{ steps.version.outputs.next-version-tag }}
          body: ${{ steps.version.outputs.changelog }}
          draft: true
```

## Configuration

Convco supports repository-level configuration via `.versionrc` (YAML/JSON) or `.convco` files in the root of your
repository. This allows you to customize:

- Custom commit types and their visibility in the changelog
- URL formats for commits, issues, and comparisons
- Scope regex validation
- Changelog template (Handlebars)
- Initial version for repos without tags

Example `.versionrc`:

```yaml
preMajor: false
scopeRegex: "^(core|web|api|shared)$"
types:
  - type: feat
    section: Features
    hidden: false
  - type: fix
    section: Bug Fixes
    hidden: false
  - type: docs
    section: Documentation
    hidden: false
  - type: chore
    hidden: true
```

See the [convco configuration docs](https://convco.github.io/configuration/) for all available options.

## How it works

This is a [composite action](https://docs.github.com/actions/sharing-automations/creating-actions/creating-a-composite-action)
made of plain Bash, so it starts in seconds:

1. **Cache**: the convco release archive for the runner's OS and architecture is restored from the Actions cache.
2. **Install** ([`src/install.sh`](src/install.sh)): the archive is downloaded from convco's GitHub release if it isn't cached, checked against its sha256, and only then unpacked and put on the `PATH`.
3. **Calculate** ([`src/calculate.sh`](src/calculate.sh)): convco reads the tags and commits to find the current version, the next one, the bump type and the changelog, which become the step's outputs.

## Security

- **Verified binary.** The action knows the sha256 of every convco release asset it supports, as GitHub reports it
  for the release. A download or a cache entry that doesn't match is refused before it runs. To use a convco version
  the action doesn't know yet, give its checksum with `convco-sha256`.
- **Pinned dependencies.** The actions this action uses are pinned by commit SHA, so pinning this action pins
  everything it runs.
- **Pin it yourself.** For the strongest guarantee, reference this action by commit SHA with the version in a comment
  (`xoadev/convco-version@<sha> # v1.1.0`) and let [Dependabot](https://docs.github.com/code-security/dependabot)
  keep it up to date.

To report a vulnerability, see [SECURITY.md](SECURITY.md).

## Requirements

- `actions/checkout@v7.0.1` with `fetch-depth: 0` (full git history)
- Linux, macOS, or Windows runner. From convco 0.7 there is no build for Intel Macs: there, set `convco-version: 0.6.3`

## Contributing

Contributions are welcome! Read [CONTRIBUTING.md](CONTRIBUTING.md) for how to run the linters, how the integration tests
work and the commit conventions.

## License

[MIT](LICENSE) © xoa.dev
