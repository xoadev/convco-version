.PHONY: lint agents-sync agents-check shellcheck shfmt actionlint zizmor markdownlint yamllint editorconfig typos

# The same checks as CI; each needs its tool on the PATH (see CONTRIBUTING.md).
lint: shellcheck shfmt actionlint zizmor markdownlint yamllint editorconfig typos

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
