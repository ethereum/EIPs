import { getOctokit } from "@actions/github";
import { context } from "@actions/github";
import { EIP, ParsedFile, PR, GITHUB_TOKEN, CommitFiles, CommitFile, Commit, FrontMatterAttributes, PrDiff, matchAll, AUTHOR_RE, joinArray } from "src/utils";
import { checkFile, parseFile } from "./CheckFile";
import { EIPs, ERRORS} from "src/main";

export type CheckPr = {
  prNum: number;
  files: ParsedFile[];
};

export type CheckPrReturn = Promise<{
  pr: PR;
}>;

export const checkPr = async ({
  prNum,
  files
}: CheckPr): CheckPrReturn => {
  const Github = getOctokit(GITHUB_TOKEN);

  const {data: pr} = await Github.pulls.get({
    repo: context.repo.repo,
    owner: context.repo.owner,
    pull_number: prNum
  });

  if (pr.merged) {
    console.error(`PR ${prNum} is already merged; quitting`);
    throw `PR ${prNum} is already merged; quitting`;
  }
  // if (pr.data.mergeable_state != "clean") {
  //   console.log(
  //     `PR ${prnum} mergeable state is ${pr.data.mergeable_state}; quitting`
  //   );
  //   return;
  // }

  // Get base and head commits
  const baseCommit = await Github.repos
    .getCommit({
      owner: context.repo.owner,
      repo: context.repo.repo,
      ref: pr.base.sha
    })
    .then((res) => res.data);

  const headCommit = await Github.repos
    .getCommit({
      owner: context.repo.owner,
      repo: context.repo.repo,
      ref: pr.head.sha
    })
    .then((res) => res.data);

  // Check for edited files
  

  const approvals = await getApprovals(pr);
  let reviewers: Set<string> = new Set();

  const indexEip = async (file: ParsedFile) => {
    try {
      const [eip, error] = await checkFile(pr, file);
      if (eip) {
        EIPs.push(eip);
      }
      if (error) {
        console.log(error);
        ERRORS.push(error);
      }
    } catch (err) {
      console.log(err);
    }
  }

  await Promise.all(
    files.map(indexEip)
  );

  EIPs.map(checkEip(approvals, reviewers));

  return { pr };
};

const filterFiles = (baseFiles: CommitFiles, headFiles: CommitFiles) => {
  if (!baseFiles) {
    if (!headFiles) {
      headFiles.map(file => file.)
    }
  }
  const allowed = baseFile
  
}

const checkEip = (approvals: string[], reviewers: Set<string>) => (eip: EIP)=> {
  
  const authors = eip.authors;
  const number: string = eip.number;
  console.log(
    `\t- EIP ${number} has authors: ${[...authors]} with size ${authors.size}`
  );
  const nonAuthors = approvals.filter((approver) => !authors.has(approver));
  console.log(`\t- EIP ${number} has non-author approvers: ${nonAuthors}`);

  if (authors.size == 0) {
    ERRORS.push(
      `EIP ${number} has no identifiable authors who can approve PRs`
    );
  } else if (nonAuthors.length > 0) {
    ERRORS.push(
      `\t- EIP ${number} requires approval from one of (${[...authors]})`
    );
    [...authors].map((author) => {
      if (author.startsWith("@")) {
        reviewers.add(author.slice(1));
      }
    });
  }
}

export const getApprovals = async (pr: PR) => {
  let approvals: Set<string> = new Set();
  if (pr.user?.login) {
    approvals.add("@" + pr.user.login.toLowerCase());
  }

  const Github = getOctokit(GITHUB_TOKEN);
  const { data: reviews } = await Github.pulls.listReviews({
    owner: context.repo.owner,
    repo: context.repo.repo,
    pull_number: pr.number
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
    `\t- Found approvers for pr number ${pr.number}: ${_approvals.join(
      " & "
    )}`
  );
  return _approvals;
};


