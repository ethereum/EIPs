import { setFailed } from "@actions/core";
import { getOctokit, context } from "@actions/github";
import { Github } from "./types";

const main = async (Github: Github) => {
  console.log({
    base: context.payload.pull_request?.base?.sha,
    head: context.payload.pull_request?.head?.sha,
    owner: context.repo.owner,
    repo: context.repo.repo
  })
  const request = await Github.repos.compareCommits({
    base: context.payload.pull_request?.base?.sha,
    head: context.payload.pull_request?.head?.sha,
    owner: context.repo.owner,
    repo: context.repo.repo
  })

  console.log(request);
  
  const headers = request.headers;
  console.log(Object.keys(headers));
  console.log(request["headers"] || "undefined");
  // console.log(headers.type);
  // if (headers)) {
    
  //   const event = request.headers["X-Github-Event"];
  //   console.log(`Got Github webhook event ${event}`);
  //   if (event == "pull_request_review") {
  //     const pr = payload["pull_request"];
  //     const prnum = pr["number"];
  //     const repo = pr["base"]["repo"]["full_name"];
  //     console.log("Processing review on PR ${repo}/${prnum}...");
  //     check_pr(repo, prnum);
  //   }
  // } else {
  //   console.log(`Processing build ${payload["number"]}...`);
  //   if (payload["pull_request_number"] === null) {
  //     console.log(
  //       "Build %s is not a PR build; quitting",
  //       payload["number"]
  //     );
  //     return;
  //   }
  //   const prnum = payload["pull_request_number"];
  //   const repo = `${payload["repository"]["owner_name"]}/${payload["repository"]["name"]}`;
  //   check_pr(repo, prnum);
  // }

  console.log(request);
}

try {
  const token = process.env.GITHUB_TOKEN;
  const Github = getOctokit(token);
  main(Github)
} catch (error) {
  setFailed(error.message);
}
