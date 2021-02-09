const core = require('@actions/core');

try {
  const regexPattern = core.getInput('regex_pattern');
  const regexFlags = core.getInput('regex_flags');
  const searchString = core.getInput('search_string');
  if (!regexPattern) {
    core.setFailed('regex_pattern input is required');
    return;
  }
  if (!regexFlags) {
    core.setFailed('regex_flags input is required');
    return;
  }
  if (!searchString) {
    core.setFailed('search_string input is required');
    return;
  }
  const regex = new RegExp(regexPattern, regexFlags);
  const matches = searchString.match(regex);
  if (!matches) {
    console.log('Could not find any matches');
    return;
  }
  console.log('Found:', matches);
  console.log('set output "first_match":', matches[0]);
  core.setOutput('first_match', matches[0]);
} catch (error) {
  core.setFailed(error.message);
}