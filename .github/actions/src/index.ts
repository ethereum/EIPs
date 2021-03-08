import { setFailed } from "@actions/core";
import { context } from "@actions/github";
import { ERRORS, main } from "src/main";
import { EVENTS } from "./utils";

if (process.env.NODE_ENV === "development") {
  console.log("establishing development context");
  context.payload.pull_request = {
    base: {
      sha: process.env.BASE_SHA
    },
    head: {
      sha: process.env.HEAD_SHA
    },
    number: 1
  };
  // @ts-ignore
  context.repo.owner = process.env.REPO_OWNER_NAME;
  // @ts-ignore
  context.repo.repo = process.env.REPO_NAME;
  context.payload.repository  = {
    // @ts-ignore
    name: process.env.REPO_NAME,
    owner: {
      key: "",
      // @ts-ignore
      login: process.env.REPO_OWNER_NAME,
      name: process.env.REPO_OWNER_NAME
    },
    full_name: `${process.env.REPO_OWNER}/${process.env.REPO_NAME}`
  };
  context.eventName = EVENTS.pullRequest;
}

try {
  void main();
} catch (error) {
  ERRORS.push(`An Exception Occured While Linting: ${error}`)
  console.log(ERRORS);
  setFailed(error.message);
  console.error(error);
}
