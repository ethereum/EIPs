#!/usr/bin/env bash
#
# Tests the artifact-fetch resilience of auto-review-bot.yml and post-ci.yml.
#
# Both workflows consume a PR-number artifact that is legitimately absent for
# some trigger events. These tests pin the static shape of the fix so a future
# edit cannot silently reintroduce a hard failure on a missing artifact. The
# embedded shell steps are also exercised for artifact and rendered-page cases.
#
# Usage:
#   tests/workflows/run.sh
#
# Exits non-zero on the first failed assertion.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
workflows="$repo_root/.github/workflows"

failures=0
pass() { printf '  ok   %s\n' "$1"; }
fail() { printf '  FAIL %s\n' "$1"; failures=$((failures + 1)); }

load_workflow() {
  ruby -ryaml -rjson -e '
    workflow = YAML.safe_load(File.read(ARGV[0]), aliases: true, permitted_classes: [Symbol])
    puts workflow.to_json
  ' "$1"
}

step_named() {
  # step_named <job.json> <name> -- prints the step object as JSON, or nothing
  ruby -rjson -e '
    job = JSON.parse(STDIN.read)
    step = (job["steps"] || []).find { |s| s["name"] == ARGV[0] }
    puts step.to_json if step
  ' "$2" <<< "$1"
}

job_json() {
  # job_json <workflow.json> <job-key> -- prints the job object as JSON
  ruby -rjson -e '
    workflow = JSON.parse(STDIN.read)
    puts workflow.fetch("jobs", {}).fetch(ARGV[0], {}).to_json
  ' "$2" <<< "$1"
}

echo "auto-review-bot.yml"
arb_json="$(load_workflow "$workflows/auto-review-bot.yml")"
arb_job="$(job_json "$arb_json" "auto-review-bot")"

if ruby -rjson -e 'exit(JSON.parse(STDIN.read).dig("permissions", "actions") == "read" ? 0 : 1)' <<< "$arb_job"; then
  pass "auto-review-bot job requests actions:read permission"
else
  fail "auto-review-bot job is missing actions:read permission"
fi

fetch_step="$(step_named "$arb_job" "Fetch PR Number")"
if [[ -n "$fetch_step" ]] \
  && grep -q 'actions/download-artifact' <<< "$fetch_step" \
  && grep -q 'steps.find-pr-number.outputs.artifact_id' <<< "$fetch_step" \
  && ! grep -q 'if-no-artifact-found' <<< "$fetch_step"; then
  pass "Fetch PR Number downloads only an artifact found by the API"
else
  fail "Fetch PR Number is not gated on an existing artifact"
fi

if [[ -n "$fetch_step" ]] && ! grep -q '"continue-on-error":true' <<< "$fetch_step"; then
  pass "Fetch PR Number still fails on an unexpected download error"
else
  fail "Fetch PR Number masks unexpected download errors"
fi

bot_step="$(step_named "$arb_job" "Auto Review Bot")"
if [[ -n "$bot_step" ]] && grep -q "check-pr-number.outputs.exists == 'true'" <<< "$bot_step"; then
  pass "Auto Review Bot step is gated on the PR number actually being found"
else
  fail "Auto Review Bot step is not gated on artifact presence"
fi

if [[ -n "$bot_step" ]] && ! grep -q '"continue-on-error":true' <<< "$bot_step"; then
  pass "Auto Review Bot failures are not masked"
else
  fail "Auto Review Bot can still fail silently"
fi
echo

echo "post-ci.yml"
post_json="$(load_workflow "$workflows/post-ci.yml")"
post_job="$(job_json "$post_json" "on-failure")"

if ruby -rjson -e '
    perms = JSON.parse(STDIN.read).fetch("permissions", {})
    required = {"actions" => "read", "contents" => "read", "issues" => "write", "pull-requests" => "write"}
    exit(required.all? { |k, v| perms[k] == v } ? 0 : 1)
  ' <<< "$post_job"; then
  pass "on-failure job requests the permissions needed for cross-run artifact downloads"
else
  fail "on-failure job is missing a required permission"
fi

fetch_step="$(step_named "$post_job" "Fetch PR Data")"
if [[ -n "$fetch_step" ]] \
  && grep -q 'actions/download-artifact' <<< "$fetch_step" \
  && ! grep -q '"continue-on-error":true' <<< "$fetch_step" \
  && grep -q 'steps.find-pr-data.outputs.artifact_id' <<< "$fetch_step" \
  && ! grep -q 'if-no-artifact-found' <<< "$fetch_step"; then
  pass "Fetch PR Data downloads only an existing artifact without masking errors"
else
  fail "Fetch PR Data does not distinguish missing artifacts from download errors"
fi

for step_name in "Add Comment" "Add Waiting Label" "Remove Waiting Label"; do
  step="$(step_named "$post_job" "$step_name")"
  if [[ -n "$step" ]] && grep -q "check-pr-data.outputs.exists == 'true'" <<< "$step"; then
    pass "$step_name is gated on the artifact fetch having succeeded"
  else
    fail "$step_name is not gated on the artifact fetch having succeeded"
  fi
done
echo

ruby -ryaml -rtmpdir -rfileutils -ropen3 - "$workflows" <<'RUBY'
  workflows = ARGV.fetch(0)
  def assert(condition, message)
    raise message unless condition
    puts "  ok   #{message}"
  end

  def steps_for(workflows, file, job)
    YAML.safe_load(File.read(File.join(workflows, file)), aliases: true)
      .fetch("jobs").fetch(job).fetch("steps")
  end

  def run_step(step, directory, env = {})
    output = File.join(directory, "output")
    File.write(output, "")
    stdout, stderr, status = Open3.capture3(
      env.merge("GITHUB_OUTPUT" => output), "bash", "-e", "-o", "pipefail",
      "-c", step.fetch("run"), chdir: directory
    )
    [File.read(output), status.success?, stdout + stderr]
  end

  [
    ["auto-review-bot.yml", "auto-review-bot", "Find PR Number artifact", "Fetch PR Number", "Check PR Number file", "find-pr-number", "pr-number", ["pr-number.txt"]],
    ["post-ci.yml", "on-failure", "Find PR Data artifact", "Fetch PR Data", "Check PR Data", "find-pr-data", "pr_number", ["pr_number", "pr_sha", "merge_sha"]]
  ].each do |file, job, find_name, fetch_name, check_name, id, artifact_name, files|
    steps = steps_for(workflows, file, job)
    find = steps.find { |step| step["name"] == find_name }
    fetch = steps.find { |step| step["name"] == fetch_name }
    check = steps.find { |step| step["name"] == check_name }
    assert(find.fetch("run").include?(%Q(select(.name == "#{artifact_name}"))), "#{file} searches for its producer artifact name")
    condition = "steps.#{id}.outputs.artifact_id != ''"
    assert(fetch["if"] == condition && check["if"] == condition, "#{file} skips download and file validation when absent")
    assert(fetch.dig("with", "artifact-ids").include?("#{id}.outputs.artifact_id") &&
      fetch.dig("with", "run-id") == "${{ github.event.workflow_run.id }}", "#{file} downloads the discovered artifact from the triggering run")

    Dir.mktmpdir do |directory|
      gh = File.join(directory, "gh")
      File.write(gh, <<~BASH)
        #!/usr/bin/env bash
        set -euo pipefail
        [[ "$1" == api && "$2" == --paginate ]]
        [[ "$3" == repos/ethereum/EIPs/actions/runs/123/artifacts ]]
        [[ "$4" == --jq ]]
        if [[ "$MOCK_ERROR" == true ]]; then
          echo "API unavailable" >&2
          exit 1
        fi
        printf "%s" "$MOCK_ARTIFACT_ID"
      BASH
      File.chmod(0755, gh)
      env = {
        "PATH" => "#{directory}:#{ENV.fetch("PATH")}",
        "GH_REPO" => "ethereum/EIPs", "RUN_ID" => "123",
        "MOCK_ERROR" => "false", "MOCK_ARTIFACT_ID" => ""
      }
      output, success, log = run_step(find, directory, env)
      assert(success && output == "artifact_id=\n" && log.include?("::notice::"), "#{file} treats absent artifacts as an explicit skip")
      output, success, = run_step(find, directory, env.merge("MOCK_ARTIFACT_ID" => "42"))
      assert(success && output == "artifact_id=42\n", "#{file} preserves a discovered artifact ID")
      output, success, log = run_step(find, directory, env.merge("MOCK_ERROR" => "true"))
      assert(!success && output.empty? && log.include?("API unavailable"), "#{file} propagates API errors")
      _, success, log = run_step(check, directory)
      assert(!success && log.include?("::error::"), "#{file} rejects an artifact missing required files")
      files.each { |name| File.write(File.join(directory, name), "123\n") }
      output, success, = run_step(check, directory)
      assert(success && output == "exists=true\n", "#{file} accepts complete artifact contents")
      if files.length > 1
        File.unlink(File.join(directory, files.last))
        _, success, log = run_step(check, directory)
        assert(!success && log.include?("::error::"), "#{file} rejects partially populated artifacts")
      end
    end
  end

  steps = steps_for(workflows, "ci.yml", "htmlproofer")
  scope = steps.find { |step| step["id"] == "rendered-pages" }
  scope_index = steps.index(scope)
  ["Merge Repos", "Setup Ruby", "Determine Jekyll and HTMLProofer scope",
   "Build with Jekyll", "Jekyll Doctor", "HTML Proofer", "DNS Validator"].each do |name|
    step = steps.find { |candidate| candidate["name"] == name }
    assert(steps.index(step) > scope_index &&
      step["if"] == "steps.rendered-pages.outputs.run == 'true'", "#{name} is gated on rendered-page changes")
  end

  cases = {
    "workflow-only" => [[".github/workflows/ci.yml"], "run=false\n"],
    "excluded README" => [["README.md"], "run=false\n"],
    "tests-only" => [["tests/workflows/run.sh"], "run=false\n"],
    "empty diff" => [[], "run=false\n"],
    "EIP" => [["EIPS/eip-1.md"], "run=true\nfull_site=false\n"],
    "mixed workflow and EIP" => [[".github/workflows/ci.yml", "EIPS/eip-1.md"], "run=true\nfull_site=false\n"],
    "deleted EIP" => [["delete"], "run=true\nfull_site=false\n"],
    "renamed EIP" => [["rename"], "run=true\nfull_site=false\n"],
    "layout" => [["_layouts/eip.html"], "run=true\nfull_site=true\n"],
    "config" => [["_config.yml"], "run=true\nfull_site=true\n"],
    "assets" => [["assets/eip-1/image.png"], "run=true\nfull_site=true\n"],
    "root page" => [["index.html"], "run=true\nfull_site=true\n"],
    "rendered markdown" => [["CONTRIBUTING.md"], "run=true\nfull_site=true\n"],
    "dependencies" => [["Gemfile.lock"], "run=true\nfull_site=true\n"]
  }
  cases.each do |name, (paths, expected)|
    Dir.mktmpdir do |directory|
      git = lambda do |*args|
        stdout, stderr, status = Open3.capture3("git", *args, chdir: directory)
        raise stderr unless status.success?
        stdout.strip
      end
      git.call("init", "--quiet")
      FileUtils.mkdir_p(File.join(directory, "EIPS"))
      File.write(File.join(directory, "EIPS/eip-1.md"), "base\n")
      File.write(File.join(directory, "_config.yml"), "exclude: []\n")
      git.call("add", ".")
      commit = ["-c", "user.name=Workflow Tests", "-c", "user.email=tests@example.invalid", "commit", "--quiet", "-m", "fixture"]
      git.call(*commit)
      base = git.call("rev-parse", "HEAD")
      paths.each do |path|
        if path == "delete"
          File.unlink(File.join(directory, "EIPS/eip-1.md"))
        elsif path == "rename"
          File.rename(File.join(directory, "EIPS/eip-1.md"), File.join(directory, "EIPS/eip-2.md"))
        else
          FileUtils.mkdir_p(File.dirname(File.join(directory, path)))
          File.write(File.join(directory, path), path == "EIPS/eip-1.md" ? "requires: 9999\n" : "changed\n")
        end
      end
      unless paths.empty?
        git.call("add", "-A")
        git.call(*commit)
      end
      output, success, log = run_step(scope, directory, "BASE_SHA" => base, "HEAD_SHA" => git.call("rev-parse", "HEAD"))
      assert(success && output == expected, "HTMLProofer #{name}: #{output.strip} #{log.strip}")
      if ["EIP", "deleted EIP"].include?(name)
        jekyll_scope = steps.find { |step| step["name"] == "Determine Jekyll and HTMLProofer scope" }
        jekyll_scope = jekyll_scope.merge("run" => jekyll_scope.fetch("run").gsub("/tmp/", "#{directory}/"))
        _, success, log = run_step(jekyll_scope, directory, {
          "BASE_SHA" => base, "HEAD_SHA" => git.call("rev-parse", "HEAD"),
          "FULL_SITE" => "false", "GITHUB_ENV" => File.join(directory, "env")
        })
        expected_paths = name == "EIP" ? "./_site/EIPS/eip-1.html\n" : "./_site\n"
        assert(success && File.read(File.join(directory, "htmlproofer_paths.txt")) == expected_paths,
          "Jekyll scope handles #{name} with missing dependencies: #{log.strip}")
      end
      if paths.empty?
        output, success, = run_step(scope, directory, "BASE_SHA" => "missing-revision", "HEAD_SHA" => base)
        assert(!success && output.empty?, "HTMLProofer propagates diff errors instead of skipping")
      end
    end
  end
RUBY

# --- Summary -----------------------------------------------------------------
if [ "$failures" -eq 0 ]; then
  echo "all workflow tests passed"
else
  echo "$failures assertion(s) failed"
  exit 1
fi
