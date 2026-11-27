.PHONY: lint test shellcheck shfmt actionlint zizmor markdownlint yamllint editorconfig typos

# CI runs this same target; each linter needs its tool on the PATH, at the version ci.yml installs.
lint: shellcheck shfmt actionlint zizmor markdownlint yamllint editorconfig typos

# The action's scripts against local git repositories; test.yml also runs the action itself, which needs a runner.
test:
	.github/scripts/test.sh

shellcheck:
	shellcheck --severity=style src/*.sh .github/scripts/*.sh

shfmt:
	shfmt --diff src .github/scripts

actionlint:
	actionlint

zizmor:
	zizmor --config .github/zizmor.yml .

markdownlint:
	markdownlint-cli2 --config .github/etc/.markdownlint.json '**/*.md' '#**/node_modules'

yamllint:
	yamllint --strict --config-file .github/etc/.yamllint.yml .

editorconfig:
	editorconfig-checker

typos:
	typos
