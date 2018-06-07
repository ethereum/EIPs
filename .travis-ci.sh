#!/bin/bash
set -e # halt script on error

HTMLPROOFER_OPTIONS="./_site --internal-domains=eips.ethereum.org --check-html --check-opengraph --report-missing-names --log-level=:debug --assume-extension --empty-alt-ignore --url-ignore=/EIPS/eip-1,EIPS/eip-1,/EIPS/eip-107,/EIPS/eip-858"

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
  BAD_FILES="$(ls EIPS | egrep -v "eip-[0-9]+.md|eip-20-token-standard.md")" || true
  if [[ ! -z $BAD_FILES ]]; then
    echo "Files found with invalid names:"
    echo $BAD_FILES
    exit 1
  fi

  FILES="$(ls EIPS/*.md | egrep  "^eip-[0-9]+.md$")"
  bundle exec eip_validator $FILES
fi
