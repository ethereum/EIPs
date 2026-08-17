#!/usr/bin/env ruby
# frozen_string_literal: true

# Regression tests for the PR-number artifact handoff between workflows.
#
# Both Auto Review Bot and Post CI failed continuously on master because they
# consume an artifact that is legitimately absent for some trigger events
# (dawidd6/action-download-artifact defaults to if_no_artifact_found: fail).

require 'yaml'
require 'set'

WORKFLOW_DIR = File.expand_path('../.github/workflows', __dir__)

Workflow = Struct.new(:name, :doc)

def workflows
  @workflows ||= Dir.glob(File.join(WORKFLOW_DIR, '*.yml')).sort.map do |path|
    Workflow.new(File.basename(path), YAML.safe_load(File.read(path), aliases: true, permitted_classes: [Date]))
  end
end

def steps(workflow)
  Array(workflow.doc['jobs']&.values).flat_map { |job| Array(job['steps']) }
end

def download_steps(workflow)
  steps(workflow).select { |step| step['uses'].to_s.include?('download-artifact') }
end

# `gh api ... --jq '.artifacts[] | select(.name == "a" or .name == "b")'` succeeds
# if any one of the listed names matches, so treat them as a single group.
def shell_artifact_groups(step)
  script = step['run'].to_s
  script.scan(/select\([^)]*\)/).filter_map do |clause|
    names = clause.scan(/\.name\s*==\s*"([^"]+)"/).flatten
    names.empty? ? nil : names
  end
end

failures = []

# ---------------------------------------------------------------------------
# 1. Every consumed artifact name must be produced somewhere.
# ---------------------------------------------------------------------------
uploaded = Set.new
consumed = []

workflows.each do |workflow|
  steps(workflow).each do |step|
    name = step.dig('with', 'name')
    uploaded << name if step['uses'].to_s.include?('upload-artifact') && name

    consumed << { names: [name], source: "#{workflow.name} / #{step['name']}" } if step['uses'].to_s.include?('download-artifact') && name
    shell_artifact_groups(step).each do |group|
      consumed << { names: group, source: "#{workflow.name} / #{step['name']}" }
    end
  end
end

failures << 'parser matched no uploaded artifacts' if uploaded.empty?
failures << 'parser matched no consumed artifacts' if consumed.empty?

consumed.each do |entry|
  next if entry[:names].any? { |n| uploaded.include?(n) }

  failures << "#{entry[:source]} consumes #{entry[:names].inspect}, " \
              "but no workflow uploads any of those names (uploaded: #{uploaded.to_a.sort.inspect})"
end

# ---------------------------------------------------------------------------
# 2. Consumers must tolerate the artifact being absent.
#
# The artifact is conditional: auto-review-trigger only uploads when it wrote a
# PR number, and ci.yml only uploads on pull_request events. Any consumer that
# hard-fails on a missing artifact will fail on every other trigger.
# ---------------------------------------------------------------------------
TOLERANT_IF_NO_ARTIFACT = %w[warn ignore].freeze

workflows.each do |workflow|
  download_steps(workflow).each do |step|
    label = "#{workflow.name} / #{step['name']}"
    tolerant = step['continue-on-error'] == true ||
               TOLERANT_IF_NO_ARTIFACT.include?(step.dig('with', 'if_no_artifact_found').to_s)

    failures << "#{label} fails the job when the artifact is missing; " \
                'set continue-on-error: true or if_no_artifact_found: warn' unless tolerant
  end
end

# ---------------------------------------------------------------------------
# 3. Cross-run artifact downloads need actions: read.
# ---------------------------------------------------------------------------
workflows.each do |workflow|
  next unless workflow.doc['on'].is_a?(Hash) && workflow.doc['on'].key?('workflow_run')

  Array(workflow.doc['jobs']).each do |job_name, job|
    consumes = Array(job['steps']).any? do |step|
      step['uses'].to_s.include?('download-artifact') || !shell_artifact_groups(step).empty?
    end
    next unless consumes

    permissions = job['permissions']
    granted = permissions.is_a?(Hash) && %w[read write].include?(permissions['actions'].to_s)
    failures << "#{workflow.name} / #{job_name} downloads an artifact from another run " \
                'but does not grant the actions: read permission' unless granted
  end
end

if failures.empty?
  puts "ok: #{consumed.length} artifact consumer(s), #{uploaded.length} uploaded name(s)"
  exit 0
end

failures.each { |failure| warn "FAIL: #{failure}" }
exit 1
