import { context, getOctokit } from "@actions/github";
import { GITHUB_TOKEN } from "src/utils/constants";
import { checkPr, checkRequest, merge, postComment, getFiles } from "src/lib";
import { ParsedFile } from "./utils";

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

export const main = async () => {
  const request = await getRequest();

  if (!request) {
    throw "request is not defined";
  }

  const { repoName, prNum, owner } = await checkRequest(request);
  const { files } = await getFiles(request);
  const { errors, pr, eips } = await checkPr({
    repoName,
    prNum,
    owner,
    files: files as ParsedFile[]
  });

  // if no errors, then merge
  if (errors.length === 0) {
    return await merge({ pr, eips });
  }

  if (errors.length > 0 && eips.length > 0) {
    return await postComment({ errors, pr, eips });
  }
};
