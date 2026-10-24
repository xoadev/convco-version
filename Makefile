.PHONY: lint test agents-sync agents-check shellcheck shfmt actionlint zizmor markdownlint yamllint editorconfig typos

# CI runs this same target; each linter needs its tool on the PATH, at the version ci.yml installs.
lint: agents-check shellcheck shfmt actionlint zizmor markdownlint yamllint editorconfig typos

# ponytail: the integration tests are the jobs of test.yml, which run this action with `uses: ./` on every pull
# request; only a GitHub runner does that, so nothing runs here. `act` could run them locally if that is ever needed.
test:
	@echo 'The integration tests run in GitHub Actions on every pull request: .github/workflows/test.yml'

shellcheck:
	shellcheck --severity=style src/*.sh .github/scripts/*.sh

shfmt:
	shfmt --diff src .github/scripts

actionlint:
	actionlint

zizmor:
	zizmor --config .github/zizmor.yml .

markdownlint:
	markdownlint-cli2 --config .github/etc/.markdownlint.json '**/*.md'

yamllint:
	yamllint --strict --config-file .github/etc/.yamllint.yml .

editorconfig:
	editorconfig-checker

typos:
	typos

# The shared head of AGENTS.md, above its <!-- xoadev:end --> line, comes from AGENTS_URL.
AGENTS_URL := https://xoa.dev/_dev/OSS_AGENTS.md
AGENTS_SCRIPT := https://xoa.dev/_dev/agents.sh

agents-sync agents-check: ## Sync (agents-sync) or check (agents-check) the shared head of AGENTS.md
	@if s=$$(curl -fsS --max-time 20 '$(AGENTS_SCRIPT)'); then sh -c "$$s" agents $(@:agents-%=%) '$(AGENTS_URL)'; \
	else echo "warning: $(AGENTS_SCRIPT) unreachable, $@ not run" >&2; [ $@ = agents-check ]; fi
