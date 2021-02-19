import { setFailed } from "@actions/core";
import { getOctokit, context } from "@actions/github";
import { check_pr } from "./lib";
import { Github } from "./types";



const main = async (Github: Github) => {
  const request = await Github.repos.compareCommits({
    base: context.payload.pull_request?.base?.sha,
    head: context.payload.pull_request?.head?.sha,
    owner: context.repo.owner,
    repo: context.repo.repo
  }).catch(() => {});
  const payload = context.payload;
  
  console.log(1);
  if (request && request.headers) {
    const event = context.eventName;
    console.log(`Got Github webhook event ${event}`);
    if (event == "pull_request") {
      const pr = payload.pull_request;
      const prnum = pr.number;
      const repo = payload.repository.full_name;
      console.log(`Processing review on PR ${repo}/${prnum}...`);
      check_pr(request, Github)(repo, prnum);
    }
  } else {
    console.log(`Processing build ${payload.sender.type}...`);
    if (!payload.pull_request?.number) {
      console.log(
        "Build ?? is not a PR build; quitting"
      );
      return;
    }
    const prnum = payload.pull_request.number;
    const repo = `${payload.repository.owner.name}/${payload.repository.name}`;
    console.log(`prnum: ${prnum}, repo: ${repo}`)
    check_pr(request, Github)(repo, prnum);
  }

  // console.log(request);
}

try {
  const token = process.env.GITHUB_TOKEN;
  const Github = getOctokit(token);
  main(Github)
} catch (error) {
  setFailed(error.message);
}
