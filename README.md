# convco-version

![CI](https://github.com/xoadev/convco-version/actions/workflows/ci.yml/badge.svg)
![Tests](https://github.com/xoadev/convco-version/actions/workflows/test.yml/badge.svg)

GitHub Action to calculate current and next version using [convco](https://github.com/convco/convco) and conventional commits.

## Features

- Calculate current and next semantic version from git history
- Generate changelog for the next release
- Detect bump type (major, minor, patch)
- Detect if there are unreleased changes
- Monorepo support via path filtering
- Force bump type override
- Fast execution with GitHub Actions caching (no Docker build overhead)
- Cross-platform: Linux, macOS, Windows

## Inputs

| Input | Description | Default |
| --- | --- | --- |
| `tag-prefix` | Prefix for version tags | `v` |
| `paths` | Comma-separated paths to filter commits (monorepo support) | `.` |
| `convco-version` | Version of convco to install | `0.6.3` |
| `bump-type` | Force bump type: `major`, `minor`, or `patch` | _(auto-detect)_ |
| `working-directory` | Run convco from this path (useful for per-package `.versionrc`) | _(root)_ |
| `initial-version` | Initial version to use if no version tags exist | _(empty)_ |

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
| `cache-hit` | `true` if convco was loaded from cache |

## Usage

### Basic

```yaml
name: Release
on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6.0.2
        with:
          fetch-depth: 0

      - uses: xoadev/convco-version@v1
        id: version

      - name: Create Release
        if: steps.version.outputs.has-changes == 'true'
        uses: softprops/action-gh-release@v2.6.2
        with:
          tag_name: ${{ steps.version.outputs.next-version-tag }}
          name: Release ${{ steps.version.outputs.next-version }}
          body: ${{ steps.version.outputs.changelog }}
          draft: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
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
      - uses: actions/checkout@v6.0.2
        with:
          fetch-depth: 0

      - uses: xoadev/convco-version@v1
        id: version

      - name: Build
        run: |
          echo "Building version ${{ steps.version.outputs.next-version }}"
          # docker build -t myapp:${{ steps.version.outputs.next-version }} .
```

### Force bump type

```yaml
- uses: xoadev/convco-version@v1
  id: version
  with:
    bump-type: major  # Force a major release regardless of commits
```

### Conditional release based on bump type

```yaml
- name: Create Major Release
  if: steps.version.outputs.bump-type == 'major'
  uses: softprops/action-gh-release@v2.6.2
  with:
    tag_name: ${{ steps.version.outputs.next-version-tag }}
    name: Major Release ${{ steps.version.outputs.next-version }}
    body: ${{ steps.version.outputs.changelog }}
```

### New repository (no tags)

```yaml
- uses: xoadev/convco-version@v1
  id: version
  with:
    initial-version: '1.0.0'
```

## Monorepo

The `paths` input filters commits that affect specific directories. This is essential for monorepos where each package maintains its own version.

### How it works

Convco analyzes commits that touch the specified paths. Only commits modifying files within those paths are considered when calculating the next version.

### Single package

```yaml
# packages/core/package.json
- uses: xoadev/convco-version@v1
  with:
    paths: 'packages/core'
```

Only commits touching `packages/core/**` will affect the version.

### Multiple packages

```yaml
# packages/web and packages/shared
- uses: xoadev/convco-version@v1
  with:
    paths: 'packages/web,packages/shared'
```

Commits touching either path are considered together.

### Per-package .versionrc

Use `working-directory` to run convco from a subdirectory that has its own `.versionrc`:

```yaml
- uses: xoadev/convco-version@v1
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

jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      core: ${{ steps.filter.outputs.core }}
      web: ${{ steps.filter.outputs.web }}
    steps:
      - uses: dorny/paths-filter@v4.0.1
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
      - uses: actions/checkout@v6.0.2
        with:
          fetch-depth: 0

      - uses: xoadev/convco-version@v1
        id: version
        with:
          paths: 'packages/core'

      - uses: softprops/action-gh-release@v2.6.2
        with:
          tag_name: core-${{ steps.version.outputs.next-version-tag }}
          body: ${{ steps.version.outputs.changelog }}
          draft: true

  release-web:
    needs: changes
    if: needs.changes.outputs.web == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6.0.2
        with:
          fetch-depth: 0

      - uses: xoadev/convco-version@v1
        id: version
        with:
          paths: 'packages/web'

      - uses: softprops/action-gh-release@v2.6.2
        with:
          tag_name: web-${{ steps.version.outputs.next-version-tag }}
          body: ${{ steps.version.outputs.changelog }}
          draft: true
```

## Configuration

Convco supports repository-level configuration via `.versionrc` (YAML/JSON) or `.convco` files in the root of your repository. This allows you to customize:

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

## Requirements

- `actions/checkout@v6.0.2` with `fetch-depth: 0` (full git history)
- Linux, macOS, or Windows runner
