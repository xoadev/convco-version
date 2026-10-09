# Contributing

Thanks for helping improve convco-version! This guide covers what you need to open a pull request that passes CI.

## Project layout

| Path | What it is |
| --- | --- |
| [`action.yml`](action.yml) | The composite action: inputs, outputs and steps |
| [`src/install.sh`](src/install.sh) | Downloads convco, checks its sha256 and puts it on the `PATH` |
| [`src/calculate.sh`](src/calculate.sh) | Runs convco and writes the step's outputs |
| [`.github/workflows/test.yml`](.github/workflows/test.yml) | Integration tests, run against the action itself |
| [`.github/workflows/ci.yml`](.github/workflows/ci.yml) | Linters and commit checks |
| [`.github/workflows/release-draft.yml`](.github/workflows/release-draft.yml) | Drafts the next release on every push to `main` |
| [`.github/scripts/check-readme-version.sh`](.github/scripts/check-readme-version.sh) | Checks the README's examples use the version being released |

## Commits

Every commit, and the pull request title, must follow [Conventional Commits](https://www.conventionalcommits.org/):
the action computes its own releases from them, and CI checks them with `convco check`.

```text
<type>(<scope>): <description>
```

Use the types `feat`, `fix`, `docs`, `ci`, `chore`, `refactor`, `test` or `style`, and append `!` to the type for a
breaking change (`feat!: drop convco 0.6`).

## Tests

Every feature is covered by an integration test in [`test.yml`](.github/workflows/test.yml): each job builds a small
git history, runs the action with `uses: ./` and checks its outputs. Add a job there for any behavior you add or
change. There is no unit test suite on purpose: the integration tests are the source of truth.

## Linters

CI runs these on every pull request; `make lint` runs the same checks locally with the tools on your `PATH`, at the
versions pinned in [`ci.yml`](.github/workflows/ci.yml).

| Linter | Checks |
| --- | --- |
| [ShellCheck](https://www.shellcheck.net/) | Bash scripts in `src/` and `.github/scripts/` |
| [shfmt](https://github.com/mvdan/sh) | Bash formatting, configured in [`.editorconfig`](.editorconfig) |
| [actionlint](https://github.com/rhysd/actionlint) | Workflow syntax and expressions |
| [zizmor](https://docs.zizmor.sh/) | Workflow and action security, configured in [`.github/zizmor.yml`](.github/zizmor.yml) |
| [markdownlint](https://github.com/DavidAnson/markdownlint-cli2) | Markdown style |
| [yamllint](https://yamllint.readthedocs.io/) | YAML style, in strict mode |
| [editorconfig-checker](https://editorconfig-checker.github.io/) | Indentation, line endings and final newlines |
| [typos](https://github.com/crate-ci/typos) | Spelling |

## Dependencies

- Pin every dependency, action and tool to a full version (`actions/checkout@v7.0.1`, never `@v7` or `@latest`).
- Actions are pinned by commit SHA with the version in a comment. [Dependabot](.github/dependabot.yml) keeps them up
  to date, and [Renovate](renovate.json) keeps convco's default version up to date.
- A new convco version needs the sha256 of each of its assets in [`src/install.sh`](src/install.sh), as GitHub reports
  them for the release:

  ```sh
  gh api repos/convco/convco/releases/tags/v<version> --jq '.assets[] | "\(.name) \(.digest)"'
  ```

## Releases

On every push to `main`, the [Release Draft](.github/workflows/release-draft.yml) workflow runs this action on its
own history and drafts the next release with its changelog. A maintainer reviews and publishes it.

A pull request that releases a version (a `feat:` or `fix:` title, or a breaking change with `!`) must also point the
README's examples at that version, since the Marketplace shows the README of the release's tag. CI works out the
version the squash merge will release and checks every `xoadev/convco-version@…` in the README against it; the Release
Draft workflow checks it again before drafting.

Releases are immutable: once published, their tag can't be moved or deleted. Before publishing a draft, tick
*Publish this Action to the GitHub Marketplace* (category *Continuous integration*) so the Marketplace lists it.
