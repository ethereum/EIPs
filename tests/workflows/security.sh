#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
workflows="$repo_root/.github/workflows"

ruby -ryaml -e '
  failures = []

  Dir[File.join(ARGV.fetch(0), "*.yml")].sort.each do |path|
    workflow = YAML.safe_load(File.read(path), aliases: true, permitted_classes: [Symbol])
    jobs = workflow.fetch("jobs", {})
    unless workflow.key?("permissions") || jobs.values.all? { |job| job.is_a?(Hash) && job.key?("permissions") }
      failures << "#{path}: workflow or every job must declare permissions"
    end

    jobs.each_value do |job|
      next unless job.is_a?(Hash)

      Array(job["steps"]).each do |step|
        next unless step.is_a?(Hash)
        uses = step["uses"]
        next unless uses

        owner_action, ref = uses.split("@", 2)
        unless owner_action.start_with?("./") || (ref && ref.match?(/\A[0-9a-f]{40}\z/))
          failures << "#{path}:#{uses}: external actions must use a full commit SHA"
        end

        if owner_action == "actions/checkout"
          unless step.dig("with", "persist-credentials") == false
            failures << "#{path}:#{uses}: checkout must set persist-credentials: false"
          end
        end
      end
    end
  end

  if failures.empty?
    puts "workflow security audit passed"
  else
    warn failures.join("\n")
    exit 1
  end
' "$workflows"

if grep -RInE 'run:.*\$\{\{[^}]*github\.(event|head_ref|ref)|run:.*\$\{\{[^}]*inputs\.' "$workflows"; then
  echo "workflow security audit failed: untrusted expressions appear directly in run commands" >&2
  exit 1
fi

echo "workflow shell interpolation audit passed"
