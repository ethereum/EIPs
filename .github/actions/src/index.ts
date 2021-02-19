import { setFailed } from "@actions/core";
import { getOctokit, context } from "@actions/github";
import { check_pr } from "./lib";
import { Github } from "./types";

if (process.env.NODE_ENV === "development") {
  console.log("establishing development context")
  context.payload.pull_request = {
    base: {
      sha: process.env.BASE_SHA
    },
    head: {
      sha: process.env.HEAD_SHA
    },
    number: 1
  }
  context.repo.owner = process.env.REPO_OWNER_NAME;
  context.repo.repo = process.env.REPO_NAME;
  context.payload.repository = { 
    name: process.env.REPO_NAME,
    owner: {
      key: "",
      login: process.env.REPO_OWNER_NAME,
      name: process.env.REPO_OWNER_NAME
    },
    full_name: `${process.env.REPO_OWNER}/${process.env.REPO_NAME}`
  };
  context.eventName = "pull_request";
}


const main = async (Github: Github) => {
  const request = await Github.repos.compareCommits({
    base: context.payload.pull_request?.base?.sha,
    head: context.payload.pull_request?.head?.sha,
    owner: context.repo.owner,
    repo: context.repo.repo
  }).catch(() => {});
  const payload = context.payload;
  
  if (request && request.headers) {
    const event = context.eventName;
    console.log(`Got Github webhook event ${event}`);
    if (event == "pull_request") {
      const pr = payload.pull_request;
      const prnum = pr.number;
      const reponame = payload.repository.full_name;
      console.log(`Processing review on PR ${reponame}/${prnum}...`);
      check_pr(request, Github)(context.repo.repo, prnum, context.repo.owner);
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
    if (request) check_pr(request, Github)(repo, prnum, context.repo.owner);
  }
}

try {
  const token = process.env.GITHUB_TOKEN;
  const Github = getOctokit(token);
  main(Github)
} catch (error) {
  setFailed(error.message);
}
