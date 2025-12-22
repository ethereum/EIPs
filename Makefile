.PHONY: help setup lint lint-eipw lint-md lint-spell site

help:
	@echo "Targets:"
	@echo "  make lint        - run common linters used in CI (best effort)"
	@echo "  make lint-eipw    - run eipw validator"
	@echo "  make lint-md      - run markdownlint (if installed)"
	@echo "  make lint-spell   - run codespell (if installed)"
	@echo "  make site         - serve the Jekyll site locally"
	@echo ""
	@echo "Notes:"
	@echo "  - eipw: cargo install eipw"
	@echo "  - site: bundle install"

setup:
	@echo "Install eipw: cargo install eipw"
	@echo "Install site deps: bundle install"

lint: lint-eipw lint-md lint-spell
	@echo "Done."

lint-eipw:
	@command -v eipw >/dev/null 2>&1 || (echo "eipw not found. Run: cargo install eipw" && exit 1)
	eipw --config ./config/eipw.toml EIPS

lint-md:
	@command -v markdownlint >/dev/null 2>&1 || (echo "markdownlint not found (ok). Skipping." && exit 0)
	markdownlint "**/*.md"

lint-spell:
	@command -v codespell >/dev/null 2>&1 || (echo "codespell not found (ok). Skipping." && exit 0)
	codespell .

site:
	bundle exec jekyll serve
