import { context, getOctokit } from "@actions/github";
import { GITHUB_TOKEN } from "src/utils/constants";
import { assertPr, merge, postComment, getFileDiff, isFilePreexisting, isValidEipFilename, checkEIP, assertEvent, assertPullNumber } from "src/lib";
import { EIP, CompareCommits, File, Repo } from "./utils";
import { checkApprovals } from "./lib/CheckApprovals";

export const ERRORS: string[] = [];
export const EIPs: EIP[] = [];

export const main = async () => {
  const Github = getOctokit(GITHUB_TOKEN);
  
  // Verifies correct enviornment and request context
  assertEvent();
  assertPullNumber();
  await assertPr();
  
  // Collect the changes made in the given PR from base <-> head
  const comparison: CompareCommits = await Github.repos
    .compareCommits({
      base: context.payload.pull_request?.base?.sha,
      head: context.payload.pull_request?.head?.sha,
      owner: context.repo.owner,
      repo: context.repo.repo
    })
    .then(res => {
      return res.data
    })

  // Filter PR's files to get EIP files only
  const allFiles = comparison.files;
  const editedFiles = allFiles.filter(isFilePreexisting);
  const eipFiles = editedFiles.filter(isValidEipFilename);

  // Extracts relevant information from file at base and head of PR 
  const fileDiffs = await Promise.all(eipFiles.map(getFileDiff));
  
  // Check each EIP file
  fileDiffs.map(checkEIP);
  
  // Check each approval list
  await Promise.all(fileDiffs.map(checkApprovals));
  console.log(ERRORS);

  // if no errors, then merge
  if (ERRORS.length === 0) {
    console.log("merging")
    return await merge(fileDiffs);
  }

  if (ERRORS.length > 0) {
    return await postComment();
  }
};
