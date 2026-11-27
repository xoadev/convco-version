# AGENTS.md

XOA's shared rules come with the `xoa` plugin of `xoadev/xoa-agents` (`XOA_RULES` is `oss` in
`.claude/settings.json`); what follows is this repository's own, and prevails where it is more
specific.

## Production

- **In production**: a public GitHub Action with tagged releases that other repositories use, so what is published only grows: its inputs, outputs and behaviour are added to, never removed or renamed.

## Versioning

- In `action.yml`, actions are pinned by commit SHA too: a workflow that pins this action by SHA does not pin what it uses.
- A new convco version needs the sha256 of each of its assets in `src/install.sh`, as GitHub reports them for the release (`gh api repos/convco/convco/releases/tags/v<version> --jq '.assets[] | "\(.name) \(.digest)"'`).
- Dependabot updates the actions (workflows and `action.yml`) and the linters' lockfiles in `.github/etc`; Renovate only updates convco's default version.

## Linting

- `make lint` runs ShellCheck (style severity), shfmt, actionlint, zizmor, markdownlint, yamllint (strict), editorconfig-checker and typos; the Lint job in `ci.yml` installs them at pinned versions and runs `make lint`.
- The uv and pnpm linters are installed from lockfiles in `.github/etc`, transitive dependencies included: after editing `pyproject.toml`, run `uv lock` there (its `exclude-newer` keeps out what is less than a week old; CI pins uv's version in `ci.yml`, and locally `uv sync --frozen --project .github/etc` puts the linters in `.github/etc/.venv/bin`); after editing `package.json`, run `pnpm install --lockfile-only` (pnpm pinned in its `packageManager`; `pnpm-workspace.yaml` sets the one-week `minimumReleaseAge`, and no dependency's install script runs).
- A pull request whose title releases a version updates the README's examples to it; `.github/scripts/check-readme-version.sh` enforces it in CI.

## Testing

- All features must be verified via integration tests running in GitHub Actions workflows (`.github/workflows/test.yml`), whose jobs run the action with `uses: ./`.
- `make test` runs `.github/scripts/test.sh`: the same cases against `src/*.sh` and throwaway git repositories, without a runner (it needs the network to download convco). A behavior added or changed gets a case in both; CI runs `make test` too.
- Do not create unit test suites (like Bats) unless explicitly requested. Integration tests are the source of truth.

## Commits

- CI checks every commit and the pull request title with `convco check`, using this action itself: convco's default types apply.
