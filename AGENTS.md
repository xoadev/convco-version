# AGENTS.md

## Versioning

- Always use full version pins for all dependencies, actions, and tools (e.g., `actions/checkout@v6.0.2`, not `actions/checkout@v6` or `actions/checkout@latest`).

## Testing

- All features must be verified via integration tests running in GitHub Actions workflows.
- Do not create unit test suites (like Bats) unless explicitly requested. Integration tests are the source of truth.

## Commits

- All commit messages must follow [Conventional Commits](https://www.conventionalcommits.org/).
- Use types: `feat`, `fix`, `docs`, `ci`, `chore`, `refactor`, `test`, `style`.
- Format: `<type>(<scope>): <description>` or `<type>: <description>`.
- Breaking changes: append `!` to type (e.g., `feat!: breaking change`).
