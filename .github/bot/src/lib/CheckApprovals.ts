import { context, getOctokit } from "@actions/github";
import { GITHUB_TOKEN, ERRORS } from "src/utils";
import { assertAuthors, assertPr } from "./Assertions";
import { FileDiff } from "./GetFileDiff";

export const removeApproved = async (file: FileDiff) => {
  const approvals = await getApprovals();
  const authors = assertAuthors(file);

  // remove approvals from authors present on base commit
  const hasAuthorApproval = !!approvals.find((approver) =>
    authors.includes(approver)
  );

  if (hasAuthorApproval) return;

  ERRORS.push(
    `${file.head.name} requires approval from one of (${authors.map(
      getJustLogin
    )})`
  );
  return file;
};

const getJustLogin = (author: string) => {
  if (author.startsWith("@")) {
    return author.slice(1);
  }
  return author;
};

export const requestReviewers = async (reviewers: string[]) => {
  const Github = getOctokit(GITHUB_TOKEN);
  const pr = await assertPr();

  await Github.pulls.requestReviewers({
    owner: context.repo.owner,
    repo: context.repo.repo,
    pull_number: pr.number,
    reviewers: reviewers.map(getJustLogin)
  });
};

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
    const reviewer = review.user?.login;
    if (isApproval && reviewer) {
      approvals.add("@" + reviewer.toLowerCase());
    }
  }

  return [...approvals];
};
