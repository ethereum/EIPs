import { context } from "@actions/github";
import { Request } from "src/utils";

type CheckRequestReturn = Promise<{
  repoName: string;
  prNum: number;
  owner: string;
}>;

export const checkRequest = async (
  request: Request | void
): CheckRequestReturn => {
  const payload = context.payload;

  if (request && request.headers) {
    const event = context.eventName;
    console.log(`Got Github webhook event ${event}`);
    if (event == "pull_request") {
      const pr = payload.pull_request;
      if (!pr) {
        throw "Must be a PR request";
      }
      const prNum = pr.number;

      console.log(`Processing review on PR ${context.repo.repo}/${prNum}...`);
      return {
        repoName: context.repo.repo,
        prNum,
        owner: context.repo.owner
      };
    }
  }

  console.log(`Processing build ${payload.sender?.type}...`);
  if (!payload.pull_request?.number) {
    console.log("Build ?? is not a PR build; quitting");
    throw "not a PR build";
  }

  const prNum = payload.pull_request.number;
  const repoName = `${payload.repository?.owner.name}/${payload.repository?.name}`;
  console.log(`prnum: ${prNum}, repo: ${repoName}`);

  return {
    repoName,
    prNum,
    owner: context.repo.owner
  };
};
