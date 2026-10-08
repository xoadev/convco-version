.PHONY: lint shellcheck shfmt actionlint zizmor markdownlint yamllint editorconfig typos

# The same checks as CI; each needs its tool on the PATH (see CONTRIBUTING.md).
lint: shellcheck shfmt actionlint zizmor markdownlint yamllint editorconfig typos

shellcheck:
	shellcheck --severity=style src/*.sh

shfmt:
	shfmt --diff src

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
