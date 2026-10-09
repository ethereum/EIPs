#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
manifest="$repo_root/config/shared-workflow-manifest.yml"

ruby -ryaml -e '
  manifest = YAML.safe_load_file(ARGV.fetch(0), aliases: true)
  abort "manifest version must be positive" unless manifest.fetch("version").to_i > 0
  files = manifest.fetch("files")
  abort "manifest has duplicate paths" unless files.map { |file| file.fetch("path") }.uniq.length == files.length
  files.each do |file|
    path = File.join(ARGV.fetch(1), file.fetch("path"))
    abort "manifested file is missing: #{file.fetch("path")}" unless File.file?(path)
    abort "manifested file has no owner: #{file.fetch("path")}" if file.fetch("owner", "").empty?
    abort "manifested file has no compatibility version: #{file.fetch("path")}" if file.fetch("compatibility", "").to_s.empty?
  end
  puts "shared workflow manifest passed: #{files.length} files, version #{manifest.fetch("version")}"
' "$manifest" "$repo_root"

if [[ -n "${ERCs_ROOT:-}" ]]; then
  ercs_manifest="$ERCs_ROOT/config/shared-workflow-manifest.yml"
  if [[ ! -f "$ercs_manifest" ]]; then
    echo "ERCs manifest missing: $ercs_manifest" >&2
    exit 1
  fi
  cmp -s "$manifest" "$ercs_manifest" || {
    echo "EIPs/ERCs shared workflow manifests differ" >&2
    diff -u "$manifest" "$ercs_manifest" >&2 || true
    exit 1
  }
  echo "EIPs/ERCs shared workflow manifests match"
else
  echo "ERCs comparison skipped: set ERCs_ROOT for cross-repository integration testing"
fi
