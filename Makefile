# convco-version — task runner. CI runs `make check` (ci.yml); test.yml also runs the action itself, which needs a
# runner.

# xoadev/xoa-base at the commit the project's workflows call, which Dependabot moves: make reads it
# from them, fetches it into .xoa-base/ when it is missing or at another commit, and git checks it.
XOA_BASE := $(sort $(shell sed -n 's|.*xoadev/xoa-base/\.github/[^@]*@\([0-9a-f]\{40\}\).*|\1|p' .github/workflows/*.y*ml))
$(if $(XOA_BASE),,$(error no workflow calls xoa-base yet: add the one its README shows first))
$(if $(filter 1,$(words $(XOA_BASE))),,$(error the workflows call xoa-base at $(XOA_BASE): one commit, in every uses: line))
include .xoa-base/$(XOA_BASE)/base.mk
include $(foreach linter,markdown yaml shell actions typos editorconfig,.xoa-base/$(XOA_BASE)/lint/$(linter).mk)
.xoa-base/$(XOA_BASE)/%: .xoa-base/$(XOA_BASE)/.fetched ;
.xoa-base/$(XOA_BASE)/.fetched:
	@rm -rf .xoa-base && git init -q $(@D)
	@git -C $(@D) fetch -q --depth 1 https://github.com/xoadev/xoa-base $(XOA_BASE)
	@git -C $(@D) checkout -q FETCH_HEAD && touch $@

.PHONY: check lint format test

check: lint test ## Everything ci.yml runs (`make -k check` to see every failure at once)

lint: md-lint yaml-lint shell-lint actions-lint typos-lint editorconfig-lint ## xoa-base's linters over the whole repository

format: md-format yaml-format shell-format ## Apply the Markdown's, the YAML's and the scripts' layout

test: ## The action's scripts against throwaway git repositories; test.yml runs the action itself
	@.github/scripts/test.sh
