#!/usr/bin/env bash
set -euo pipefail

version="1.7.7"
archive="actionlint_${version}_linux_amd64.tar.gz"
expected_sha256="023070a287cd8cccd71515fedc843f1985bf96c436b7effaecce67290e7e0757"
temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT

curl -fsSL "https://github.com/rhysd/actionlint/releases/download/v${version}/${archive}" \
  -o "$temporary_directory/$archive"
printf '%s  %s\n' "$expected_sha256" "$temporary_directory/$archive" | sha256sum -c -
tar -xzf "$temporary_directory/$archive" -C "$temporary_directory" actionlint
"$temporary_directory/actionlint" "$@"
