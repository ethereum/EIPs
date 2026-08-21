#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
vectors="$repo_root/tests/validation/vectors.json"

ruby -rjson -ryaml -e '
  vectors = JSON.parse(File.read(ARGV.fetch(0)))
  abort "unexpected vector schema" unless vectors.fetch("schema") == "eip-validation-vectors-1"
  cases = vectors.fetch("cases")
  abort "vector suite must not be empty" if cases.empty?
  allowed_results = %w[pass fail error]
  cases.each do |test_case|
    source = File.join(ARGV.fetch(1), test_case.fetch("source"))
    abort "missing vector source: #{test_case.fetch("source")}" unless File.file?(source)
    abort "invalid repository kind" unless %w[eip erc].include?(test_case.fetch("repository_kind"))
    abort "invalid expected result" unless allowed_results.include?(test_case.fetch("expected"))
    test_case.fetch("expected_rules").each do |rule|
      abort "empty expected rule in #{test_case.fetch("id")}" if rule.empty?
    end
  end
  puts "validation vectors passed: #{cases.length} cases"
' "$vectors" "$repo_root"
