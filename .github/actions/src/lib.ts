import { CompareCommits, EIP, File, Files, Github, ParsedFile, PR, Request } from "./types";
import { context } from "@actions/github";
import { getAuthors, parseFile, getApprovals } from "./utils";
import { getOctokit } from "@actions/github";
import { FILE_RE } from "./regex";
import { ALLOWED_STATUSES, MERGE_MESSAGE } from "./constants";

const check_file = async ({ data: pr }: PR, file: File): Promise<[{number: string, authors: Set<string>}, string]> => {
  const Github = getOctokit(process.env.GITHUB_TOKEN);
  const parsedFile = await parseFile(file);
  const fileName = parsedFile.path;

  console.log(`---- check_file: ${fileName}`);
  try {
    const match = fileName.search(FILE_RE);
    if (match === -1) {
      return [null, `File ${fileName} is not an EIP`];
    }

    const eipnum = fileName.match(/(\d+)/)[0];
    console.log(`Found EIP number as ${eipnum} for file name ${fileName}`);

    if (file.status == "added") {
      return [null, `Contains new file ${fileName}`];
    }

    console.log(
      `Getting file ${fileName} from ${pr.base.user.login}@${pr.base.repo.name}/${pr.base.sha}`
    );

    const basedata = parsedFile.content;
    console.log("got attributes...")
    console.log(basedata.attributes);

    const status = basedata.attributes["status"];
    console.log("----- Retrieving authors from EIP raw authors list")
    const authors = await getAuthors(basedata.attributes["author"]);
    console.log(`authors: ${authors}`)

    if (!ALLOWED_STATUSES.has(status.toLowerCase())) {
      return [
        null,
        `EIP ${eipnum} is in state ${status}, not Draft or Last Call`,
      ];
    }
    const eip = { number: eipnum, authors }
    
    console.log(`--------`)
    console.log(`eip attribute: ${basedata.attributes["eip"]}\textracted num: ${eipnum}`)
    if (basedata.attributes["eip"] !== parseInt(eipnum)) {
      return [
        eip,
        `EIP header in ${fileName} does not match: ${basedata.attributes["eip"]}`,
      ];
    }
    console.log(`eips in header + file name matched!`)

    // checking head <---> base
    console.log("------ Checking Head <--> Base commit consistency...")
    console.log(
      `Getting file ${fileName} from ${pr.base.user.login}@${pr.base.repo.name}/${pr.base.sha}`
    );
    const head = await Github.repos.getCommit({owner: context.repo.owner, repo: context.repo.repo, ref: pr.head.sha}); // ref=pr.head.sha
    const headdata = await parseFile(head.data.files[0] as File).then(res => res.content);
    console.log("head commit attributes...");
    console.log(headdata.attributes);
    if (headdata.attributes["eip"] != parseInt(eipnum)) {
      console.log(`head and base commits had non-matching eip numbers; head: ${headdata.attributes["eip"]} -- base: ${eipnum}`)
      return [
        eip,
        `EIP header in modified file ${fileName} does not match: ${headdata.attributes["eip"]}`,
      ];
    } else if (
      headdata.attributes["status"].toLowerCase() !=
      basedata.attributes["status"].toLowerCase()
    ) {
      console.log(`A status change was detected; head: ${headdata.attributes["status"].toLowerCase()} -- base: ${basedata.attributes["status"].toLowerCase()}`)
      return [
        eip,
        `Trying to change EIP ${eipnum} state from ${basedata.attributes["status"]} to ${headdata.attributes["status"]}`,
      ];
    }
    console.log("No errors with the file were detected!")
    return [eip, null];
  } catch (e) {
    console.warn("Exception checking file %s", file.filename);
    return [null, `Error checking file ${file.filename}`];
  }
};

export const getRequest = () => {
  const Github = getOctokit(process.env.GITHUB_TOKEN);
  return Github.repos.compareCommits({
    base: context.payload.pull_request?.base?.sha,
    head: context.payload.pull_request?.head?.sha,
    owner: context.repo.owner,
    repo: context.repo.repo
  }).catch(() => {});
}

export const checkRequest = async (request: Request) => {
  const payload = context.payload;
  
  if (request && request.headers) {
    const event = context.eventName;
    console.log(`Got Github webhook event ${event}`);
    if (event == "pull_request") {
      const pr = payload.pull_request;
      const prNum = pr.number;
      const repoName = payload.repository.full_name;
      console.log(`Processing review on PR ${repoName}/${prNum}...`);
      return {
        repoName: context.repo.repo,
        prNum,
        owner: context.repo.owner
      }
    }
  } else {
    console.log(`Processing build ${payload.sender.type}...`);
    if (!payload.pull_request?.number) {
      console.log(
        "Build ?? is not a PR build; quitting"
      );
      return;
    }
    const prNum = payload.pull_request.number;
    const repoName = `${payload.repository.owner.name}/${payload.repository.name}`;
    console.log(`prnum: ${prNum}, repo: ${repoName}`)
    return {
      repoName,
      prNum,
      owner: context.repo.owner
    }
  }
}

type CheckPr = {
  repoName: string,
  prNum: number,
  owner: string,
  request: Request
}

export const checkPr = async ({repoName, prNum, owner, request}: CheckPr) => {
  const Github = getOctokit(process.env.GITHUB_TOKEN);

  if (!request) {
    throw "request is not defined";
  }

  console.log(`Checking PR ${prNum} on ${repoName}`);
  const { data: repo } = await Github.repos.get({
    owner,
    repo: repoName,
  });
  
  console.log(`repo full name: `, repo.full_name);
  const pr = await Github.pulls.get({
    repo: repo.name,
    owner: repo.owner.login,
    pull_number: prNum,
  });

  if (pr.data.merged) {
    console.log("PR %d is already merged; quitting", prNum);
    return;
  }
  // if (pr.data.mergeable_state != "clean") {
  //   console.log(
  //     `PR ${prnum} mergeable state is ${pr.data.mergeable_state}; quitting`
  //   );
  //   return;
  // }

  const files = request.data.files;

  let eips: EIP[] = [];
  let errors = [];
  console.log("---------");
  console.log(`${files.length} file found!` || "no files");

  const contents = await Promise.all(files.map(parseFile));
  contents.map((file) =>
    console.log(`file name ${file.name} has length ${file.content.body.length}`)
  );
  console.log("---------");

  await Promise.all(files.map(async (file: File) => {
    try {
      const [eip, error] = await check_file(pr, file);
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
  }));

  console.log(`----- Getting PR approvals`)
  const approvals = await getApprovals(pr);
  
  console.log(`------ Reviewing authors and approvers`)
  let reviewers: Set<string> = new Set();
  eips.map((eip) => {
    const authors = eip.authors;
    const number: string = eip.number;
    console.log(`\t- EIP ${number} has authors: ${[...authors]} with size ${authors.size}`);
    const nonAuthors = approvals.filter(approver => !authors.has(approver));
    console.log(`\t- EIP ${number} has non-author approvers: ${nonAuthors}`)

    if (authors.size == 0) {
      errors.push(
        `EIP ${number} has no identifiable authors who can approve PRs`
      );
    } else if (nonAuthors.length > 0){
      errors.push(`\t- EIP ${number} requires approval from one of (${[...authors]})`);
      [...authors].map(author => {
        if (author.startsWith('@')) {
          reviewers.add(author.slice(1))
        }
      })
    }
  });

  return { errors, pr, files, eips }
};

type PostComment = {
  errors: string[],
  pr: PR,
  eips: EIP[]
}

export const postComment = async ({errors, pr, eips}: PostComment) => {
  const Github = getOctokit(process.env.GITHUB_TOKEN);

  let message =
    "Hi! I'm a bot, and I wanted to automerge your PR, but couldn't because of the following issue(s):\n\n";
  message += errors.join("\n\t\t - ");

  console.log(`------- Posting Comment`)
  console.log(`\t- comment body:\n\t\t"""\n\t\t${message}\n\t\t"""`);

  const {data: me} = await Github.users.getAuthenticated()
  console.log(`\t- Got user ${me.login}`)
  const {data: comments} = await Github.issues.listComments({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.issue.number
  });
  console.log(`\t- Found issue number ${context.issue.number} with ${comments.length} comments associated with it`)

  // If comment already exists, edit that
  for (const comment of comments) {
    if (comment.user.login == me.login) {
      console.log("\t- Found comment by self (github bot)");

      console.log(`\t- Current comment body:\n\t\t"""\n\t\t${comment.body}\n\t\t"""`);
      if (comment.body != message) {
        console.log(`\t- Comment differs from current errors, so updating...`)
        Github.issues.updateComment({
          owner: context.repo.owner,
          repo: context.repo.repo,
          comment_id: comment.id,
          body: message
        }).catch(err => {
          console.log(err)
        })
        return;
      }
      console.log(`\t- No change in error comment; quiting...`)
      return;
    }
  }

  // if comment does not exist, create a new one
  console.log(`\t- Posting a new comment`)
  Github.issues.createComment({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.issue.number,
    body: message
  })
}

type Merge = {
  pr: PR,
  eips: EIP[]
}

export const merge = ({pr: _pr, eips}: Merge) => {
  const pr = _pr.data;
  const prNum = pr.number;
  const Github = getOctokit(process.env.GITHUB_TOKEN);
  const eipNumbers = eips.join(", ");

  console.log(`Merging PR ${pr.number}!`);
  Github.pulls.merge({
    pull_number: pr.number,
    repo: pr.base.repo.full_name,
    owner: pr.base.repo.owner.login,
    commit_title: `Automatically merged updates to draft EIP(s) ${eipNumbers} (#${prNum})`,
    commit_message: MERGE_MESSAGE,
    merge_method: "squash",
    sha: pr.head.sha
  })

  return {
    response: `Merging PR ${prNum}!`
  }
}

// const post = (request: any, Github: Github) => {
//   const payload = JSON.parse(request["payload"]);
//   if (request.headers.includes("X-Github-Event")) {

//     const event = request.headers["X-Github-Event"];
//     console.log(`Got Github webhook event ${event}`);
//     if (event == "pull_request_review") {
//       const pr = payload["pull_request"];
//       const prnum = pr["number"];
//       const repo = pr["base"]["repo"]["full_name"];
//       console.log("Processing review on PR ${repo}/${prnum}...");
//       check_pr(repo, prnum);
//     }
//   } else {
//     console.log(`Processing build ${payload["number"]}...`);
//     if (payload["pull_request_number"] === null) {
//       console.log(
//         "Build %s is not a PR build; quitting",
//         payload["number"]
//       );
//       return;
//     }
//     const prnum = payload["pull_request_number"];
//     const repo = `${payload["repository"]["owner_name"]}/${payload["repository"]["name"]}`;
//     check_pr(repo, prnum);
//   }
// };

// const get = (request: any) => {
//   return check_pr(request["repo"], JSON.parse(request["pr"]))
// }