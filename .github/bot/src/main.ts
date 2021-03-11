import { setFailed } from "@actions/core";
import { context, getOctokit } from "@actions/github";
import {
  assertPr,
  merge,
  postComment,
  getFileDiff,
  isFilePreexisting,
  isValidEipFilename,
  checkEIP,
  assertEvent,
  assertPullNumber,
  assertAuthors,
  removeApproved,
  requestReviewers
} from "./lib";
import { CompareCommits, GITHUB_TOKEN, ERRORS } from "./utils";

export const main = async () => {
  try {
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
      .then((res) => {
        return res.data;
      });

    // Filter PR's files to get EIP files only
    const allFiles = comparison.files;
    const editedFiles = allFiles.filter(isFilePreexisting);
    const eipFiles = editedFiles.filter(isValidEipFilename);

    // Extracts relevant information from file at base and head of PR
    const fileDiffs = await Promise.all(eipFiles.map(getFileDiff));

    // Check each EIP content
    fileDiffs.map(checkEIP);

    // Check each approval list
    const notApproved = await Promise.all(fileDiffs.map(removeApproved));
    const authors = notApproved.map((file) => file && assertAuthors(file));

    // all other tests passed except missing reviewers, request reviews
    if (ERRORS.length === authors.length) {
      for (const eipAuthors of authors) {
        eipAuthors && (await requestReviewers(eipAuthors));
      }
    }

    // if no errors, then merge
    if (ERRORS.length === 0) {
      return await merge(fileDiffs);
    }

    if (ERRORS.length > 0) {
      return await postComment();
    }
  } catch (error) {
    console.error(error);
    ERRORS.push(`An Exception Occured While Linting: ${error}`);
    console.log(ERRORS);
    setFailed(error.message);
  }
};