#!/bin/bash
set -e # halt script on error

HTMLPROOFER_OPTIONS="./_site --internal-domains=eips.ethereum.org --check-html --check-opengraph --report-missing-names --log-level=:debug --assume-extension --empty-alt-ignore --timeframe=6w --url-ignore=/EIPS/eip-1,EIPS/eip-1,/EIPS/eip-107,/EIPS/eip-858"

if [[ $TASK = 'htmlproofer' ]]; then
  bundle exec jekyll doctor
  bundle exec jekyll build
  bundle exec htmlproofer $HTMLPROOFER_OPTIONS --disable-external

  # Validate GH Pages DNS setup
  bundle exec github-pages health-check
elif [[ $TASK = 'htmlproofer-external' ]]; then
  bundle exec jekyll doctor
  bundle exec jekyll build
  bundle exec htmlproofer $HTMLPROOFER_OPTIONS --external_only
elif [[ $TASK = 'eip-validator' ]]; then
  if [[ $(find . -maxdepth 1 -name 'eip-*' | wc -l) -ne 1 ]]; then
    echo "only 'eip-template.md' should be in the root"
    exit 1
  fi
  eipv EIPS/ --ignore=title_max_length,missing_discussions_to --skip=eip-20-token-standard.md
elif [[ $TASK = 'codespell' ]]; then
  codespell -q4 -I .codespell-whitelist -S ".git,Gemfile.lock,**/*.png,**/*.gif,**/*.jpg,**/*.svg,.codespell-whitelist,vendor,_site,_config.yml,style.css"
fi
