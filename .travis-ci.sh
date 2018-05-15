#!/bin/bash
set -e # halt script on error

HTMLPROOFER_OPTIONS="./_site --internal-domains=eips.ethereum.org --check-html --check-opengraph --report-missing-names --log-level=:debug --assume-extension --empty-alt-ignore --url-ignore=/EIPS/eip-1,EIPS/eip-1,/EIPS/eip-107,/EIPS/eip-858"

if [[ $TASK = 'htmlproofer' ]]; then
  bundle exec jekyll doctor
  bundle exec jekyll build
  bundle exec htmlproofer $HTMLPROOFER_OPTIONS --disable-external
elif [[ $TASK = 'htmlproofer-external' ]]; then
  bundle exec jekyll doctor
  bundle exec jekyll build
  bundle exec htmlproofer $HTMLPROOFER_OPTIONS --external_only
elif [[ $TASK = 'eip-validator' ]]; then
  bundle exec eip_validator EIPS/*.md
fi

# Validate GH Pages DNS setup
# bundle exec github-pages health-check
