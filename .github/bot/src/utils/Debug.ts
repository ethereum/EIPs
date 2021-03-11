
import { EVENTS } from "./Constants";

export const __MAIN__ = async (debugEnv?: NodeJS.ProcessEnv) => {
  const isDebug = process.env.NODE_ENV === "development" || process.env.NODE_ENV === "test"

  if (!isDebug) throw new Error("trying to run debug without proper auth");
  
  // setup debug env
  setDebugContext(debugEnv);

  // by instantiating after context and env are custom set,
  // it allows for a custom environment that's setup programmatically
  const main = require("src/main").main;
  return await main();
}

const setDebugContext = (debugEnv?: NodeJS.ProcessEnv) => {
  const env = {...process.env, ...debugEnv};
  process.env = env;

  // By instantiating after above it allows it to initialize with custom env
  const context = require("@actions/github").context;

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