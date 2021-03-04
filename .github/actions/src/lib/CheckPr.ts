import { getOctokit } from "@actions/github";
import { context } from "@actions/github";
import { EIP, ParsedFile, PR, GITHUB_TOKEN } from "src/utils";
import { checkFile } from "./CheckFile";

export type CheckPr = {
  repoName: string;
  prNum: number;
  owner: string;
  files: ParsedFile[];
};

export type CheckPrReturn = Promise<{
  errors: string[];
  pr: PR;
  eips: EIP[];
}>;

export const checkPr = async ({
  repoName,
  prNum,
  owner,
  files
}: CheckPr): CheckPrReturn => {
  const Github = getOctokit(GITHUB_TOKEN);

  console.log(`Checking PR ${prNum} on ${repoName}`);
  const { data: repo } = await Github.repos.get({
    owner,
    repo: repoName
  });

  console.log(`repo full name: `, repo.full_name);
  const pr = await Github.pulls.get({
    repo: repo.name,
    owner: repo.owner?.login || context.repo.owner,
    pull_number: prNum
  });

  if (pr.data.merged) {
    console.error(`PR ${prNum} is already merged; quitting`);
    throw `PR ${prNum} is already merged; quitting`;
  }
  // if (pr.data.mergeable_state != "clean") {
  //   console.log(
  //     `PR ${prnum} mergeable state is ${pr.data.mergeable_state}; quitting`
  //   );
  //   return;
  // }

  let eips: EIP[] = [];
  let errors: any[] = [];

  await Promise.all(
    files.map(async (file) => {
      try {
        const [eip, error] = await checkFile(pr, file);
        if (eip) {
          eips.push(eip);
        }
        if (error) {
          console.log(error);
          errors.push(error);
        }
      } catch (err) {
        console.log(err);
      }
    })
  );

  console.log(`----- Getting PR approvals`);
  const approvals = await getApprovals(pr);

  console.log(`------ Reviewing authors and approvers`);
  let reviewers: Set<string> = new Set();
  eips.map((eip) => {
    const authors = eip.authors;
    const number: string = eip.number;
    console.log(
      `\t- EIP ${number} has authors: ${[...authors]} with size ${authors.size}`
    );
    const nonAuthors = approvals.filter((approver) => !authors.has(approver));
    console.log(`\t- EIP ${number} has non-author approvers: ${nonAuthors}`);

    if (authors.size == 0) {
      errors.push(
        `EIP ${number} has no identifiable authors who can approve PRs`
      );
    } else if (nonAuthors.length > 0) {
      errors.push(
        `\t- EIP ${number} requires approval from one of (${[...authors]})`
      );
      [...authors].map((author) => {
        if (author.startsWith("@")) {
          reviewers.add(author.slice(1));
        }
      });
    }
  });

  return { errors, pr, eips };
};

export const getApprovals = async (pr: PR) => {
  let approvals: Set<string> = new Set();
  if (pr.data.user?.login) {
    approvals.add("@" + pr.data.user.login.toLowerCase());
  }

  const Github = getOctokit(GITHUB_TOKEN);
  const { data: reviews } = await Github.pulls.listReviews({
    owner: context.repo.owner,
    repo: context.repo.repo,
    pull_number: pr.data.number
  });
  console.log(`\t- ${reviews.length} reviews were found for the PR`);

  reviews.map((review) => {
    if (review.state == "APPROVED") {
      if (review.user?.login) {
        approvals.add("@" + review.user?.login.toLowerCase());
      }
    }
  });

  const _approvals = [...approvals];
  console.log(
    `\t- Found approvers for pr number ${pr.data.number}: ${_approvals.join(
      " & "
    )}`
  );
  return _approvals;
};
