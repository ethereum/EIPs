import { setFailed } from "@actions/core";
import { EVENTS, ERRORS } from "./utils";
import { context, getOctokit } from "@actions/github";
import { GITHUB_TOKEN } from "src/utils/Constants";
import { assertPr, merge, postComment, getFileDiff, isFilePreexisting, isValidEipFilename, checkEIP, assertEvent, assertPullNumber, assertAuthors, removeApproved, requestReviewers } from "src/lib";
import { CompareCommits } from "./utils";

if (process.env.NODE_ENV === "development") {
  console.log("establishing development context");
  context.payload.pull_request = {
    base: {
      sha: process.env.BASE_SHA
    },
    head: {
      sha: process.env.HEAD_SHA
    },
    number: parseInt(process.env.PULL_NUMBER || "") || 0
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

const main = async () => {
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
      .then(res => {
        return res.data
      })

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
    const authors = notApproved.map(file => file && assertAuthors(file));

    // all other tests passed except missing reviewers, request reviews
    if (ERRORS.length === authors.length) {
      for (const eipAuthors of authors) {
        eipAuthors && await requestReviewers(eipAuthors)
      }
    }

    // if no errors, then merge
    if (ERRORS.length === 0) {
      console.log("merging")
      // return await merge(fileDiffs);
    }

    if (ERRORS.length > 0) {
      return await postComment();
    }
  } catch (error) {
    console.error(error);
    ERRORS.push(`An Exception Occured While Linting: ${error}`)
    console.log(ERRORS);
    setFailed(error.message);
  }
}

main();
