import { setFailed } from "@actions/core";
import { getOctokit, context } from "@actions/github";
import { checkPr, getRequest, checkRequest, merge, postComment } from "./lib";
import { Github, Request } from "./types";

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

const main = async () => {
  const request = await getRequest();
  const {repoName, prNum, owner} = await checkRequest(request);
  const {errors, pr, files, eips} = await checkPr({repoName, prNum, owner, request});
  
  // if no errors, then merge
  if (errors.length === 0){
    return await merge({pr, eips})
  }

  if (errors.length > 0 && eips.length > 0) {
    postComment({errors, pr, eips})
  }
  
}

try {
  main()
} catch (error) {
  setFailed(error.message);
  console.log(error);
}
