#!/bin/bash
set -e # halt script on error

HTMLPROOFER_OPTIONS="./_site --internal-domains=eips.ethereum.org --check-html --check-opengraph --report-missing-names --log-level=:debug"

bundle exec jekyll doctor
bundle exec jekyll build

if [[ $TASK = 'htmlproofer' ]]; then
  bundle exec htmlproofer $HTMLPROOFER_OPTIONS --disable-external
elif [[ $TASK = 'htmlproofer-external' ]]; then
  bundle exec htmlproofer $HTMLPROOFER_OPTIONS
fi

# Validate GH Pages DNS setup
bundle exec github-pages health-check
