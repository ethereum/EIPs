import { context, getOctokit } from "@actions/github";
import { ERRORS } from "src/main";
import { EIP, GITHUB_TOKEN, PR } from "src/utils";
import { assertPr } from "./Assertions";
import { assertPullNumber } from "./Assertions";
import { FileDiff } from "./GetFileDiff";

export const checkApprovals = async (file: FileDiff) => {
  const approvals = await getApprovals();
  const authors = file.base.authors && [...file.base.authors];

  // Make sure there are authors
  if (!authors || authors.length === 0) {
    ERRORS.push(
      `${file.head.name} has no identifiable authors who can approve the PR (only considering the base version)`
    );
    return;
  } 
  
  // remove approvals from authors present on base commit
  const nonAuthorApprovals = approvals.filter((approver) => !authors?.includes(approver));
  const authorApprovals = approvals.filter((approver) => authors?.includes(approver));
  const authorsToRequest = authors.filter(author => !authorApprovals.includes(author))

  if (authorApprovals.length === 0) {
    ERRORS.push(
      `${file.head.name} requires approval from one of (${authorsToRequest.map(getJustLogin)})`
    );
  }

  // requestReviewers(authorsToRequest.map(getJustLogin));
}

const getJustLogin = (author: string) => {
  if (author.startsWith("@")){
    return author.slice(1);
  }
  return author
}

const requestReviewers = async (reviewers: string[]) => {
  const Github = getOctokit(GITHUB_TOKEN);
  const pr = await assertPr();

  return await Github.pulls.requestReviewers({
    owner: context.repo.owner,
    repo: context.repo.repo,
    pull_number: pr.number,
    reviewers 
  }).then(res => res.data.requested_reviewers?.map(reviewer => reviewer?.login))
}

const getApprovals = async () => {
  const pr = await assertPr();
  const Github = getOctokit(GITHUB_TOKEN);
  const { data: reviews } = await Github.pulls.listReviews({
    owner: context.repo.owner,
    repo: context.repo.repo,
    pull_number: pr.number
  });

  // Starting with set to prevent repeats
  const approvals: Set<string> = new Set();

  // Add self to approver list
  if (pr.user?.login) {
    approvals.add("@" + pr.user.login.toLowerCase());
  }

  // Only add approvals if the approver has a username
  for (const review of reviews) {
    const isApproval = review.state == "APPROVED";
    const reviewer = review.user?.login
    if (isApproval && reviewer) {
      approvals.add("@" + reviewer.toLowerCase());
    }
  }

  return [...approvals];
};