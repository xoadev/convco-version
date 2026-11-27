# AGENTS.md

XOA's shared rules come with the `xoa` plugin of `xoadev/xoa-agents` (`XOA_RULES` is `oss` in
`.claude/settings.json`); what follows is this repository's own, and prevails where it is more
specific.

## Production

- **In production**: a public GitHub Action with tagged releases that other repositories use, so
  what is published only grows: its inputs, outputs and behaviour are added to, never removed or
  renamed.

## Versioning

- In `action.yml`, actions are pinned by commit SHA too: a workflow that pins this action by SHA
  does not pin what it uses.
- A new convco version needs the sha256 of each of its assets in `src/install.sh`, as GitHub reports
  them for the release
  (`gh api repos/convco/convco/releases/tags/v<version> --jq '.assets[] | "\(.name) \(.digest)"'`).
- Dependabot updates the actions (workflows and `action.yml`) and xoa-base's commit with them;
  Renovate only updates convco's default version.

## Linting

- The linters are xoa-base's (`lint/*.mk`), at the commit `ci.yml` calls its linters action with;
  what each target does, in `make help`. CI runs `make -k check`.
- A pull request whose title releases a version updates the README's examples to it;
  `.github/scripts/check-readme-version.sh` enforces it in CI.

## Testing

- All features must be verified via integration tests running in GitHub Actions workflows
  (`.github/workflows/test.yml`), whose jobs run the action with `uses: ./`.
- `make test` runs `.github/scripts/test.sh`: the same cases against `src/*.sh` and throwaway git
  repositories, without a runner (it needs the network to download convco). A behavior added or
  changed gets a case in both; CI runs `make test` too.
- Do not create unit test suites (like Bats) unless explicitly requested. Integration tests are the
  source of truth.

## Commits

- CI checks every commit and the pull request title with `convco check`, using this action itself:
  convco's default types apply.
