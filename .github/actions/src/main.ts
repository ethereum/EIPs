import { context, getOctokit } from "@actions/github";
import { GITHUB_TOKEN } from "src/utils/constants";
import { checkPr, checkRequest, merge, postComment, getFiles } from "src/lib";
import { ParsedFile, EIP } from "./utils";

export const getRequest = () => {
  const Github = getOctokit(GITHUB_TOKEN);
  return Github.repos
    .compareCommits({
      base: context.payload.pull_request?.base?.sha,
      head: context.payload.pull_request?.head?.sha,
      owner: context.repo.owner,
      repo: context.repo.repo
    })
    .catch(() => {});
};

export const ERRORS: string[] = [];
export const EIPs: EIP[] = [];

export const main = async () => {
  const request = await getRequest();

  if (!request) {
    throw "request is not defined";
  }

  const { repoName, prNum, owner } = await checkRequest(request);
  const { files } = await getFiles(request);
  const { pr } = await checkPr({
    prNum,
    files: files as ParsedFile[]
  });

  // if no errors, then merge
  if (ERRORS.length === 0) {
    return await merge({ pr, eips: EIPs });
  }

  if (ERRORS.length > 0 && EIPs.length > 0) {
    return await postComment({ errors: ERRORS, pr, eips: EIPs });
  }
};
