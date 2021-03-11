import { context } from "@actions/github";
import { EVENTS } from "./Constants";

export const setEnvAsContext = (env: NodeJS.ProcessEnv) => {
  console.log("establishing development context...");
  context.payload.pull_request = {
    base: {
      sha: env.BASE_SHA
    },
    head: {
      sha: env.HEAD_SHA
    },
    number: parseInt(env.PULL_NUMBER || "") || 0
  };
  // @ts-ignore
  context.repo.owner = env.REPO_OWNER_NAME;
  // @ts-ignore
  context.repo.repo = env.REPO_NAME;
  context.payload.repository = {
    // @ts-ignore
    name: env.REPO_NAME,
    owner: {
      key: "",
      // @ts-ignore
      login: env.REPO_OWNER_NAME,
      name: env.REPO_OWNER_NAME
    },
    full_name: `${env.REPO_OWNER}/${env.REPO_NAME}`
  };
  context.eventName = EVENTS.pullRequest;
}