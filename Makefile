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

# The head of AGENTS.md, everything above AGENTS_MARK, is shared by our repositories and lives at AGENTS_URL.
AGENTS_URL := https://xoa.dev/_dev/OSS_AGENTS.md
AGENTS_MARK := <!-- xoadev:end -->

agents-sync: ## Rewrite the shared head of AGENTS.md from AGENTS_URL
	@grep -qx '$(AGENTS_MARK)' AGENTS.md || { echo "AGENTS.md has no '$(AGENTS_MARK)' line: add it below the shared head" >&2; exit 1; }
	@tmp=$$(mktemp) && trap 'rm -f "$$tmp"' EXIT && curl -fsS --max-time 20 '$(AGENTS_URL)' -o "$$tmp" \
		&& sed -n '/^$(AGENTS_MARK)$$/,$$p' AGENTS.md >> "$$tmp" && cat "$$tmp" > AGENTS.md

agents-check: ## Fail if the shared head of AGENTS.md differs from AGENTS_URL (warns when offline)
	@tmp=$$(mktemp) && trap 'rm -f "$$tmp"' EXIT; \
	if ! curl -fsS --max-time 20 '$(AGENTS_URL)' -o "$$tmp"; then \
		echo "warning: $(AGENTS_URL) unreachable, AGENTS.md not checked" >&2; exit 0; fi; \
	sed '/^$(AGENTS_MARK)$$/,$$d' AGENTS.md | diff -u "$$tmp" - >&2 \
		|| { echo "AGENTS.md: the shared head differs from $(AGENTS_URL); run make agents-sync" >&2; exit 1; }
