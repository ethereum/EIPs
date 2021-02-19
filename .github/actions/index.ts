import { getInput, setOutput, setFailed } from "@actions/core";
import {context, getOctokit } from "@actions/github";
// import frontmatter from "front-matter";
// import Github from "github-api";

// const githubToken = process.env.GITHUB_TOKEN
// const Github = getOctokit(githubToken);

const test = async (Github: any) => {
  console.log(await Github.users.getByUsername({ username: "alita-moore"}))
}

try {
  // `who-to-greet` input defined in action metadata file
  const nameToGreet = getInput("who-to-greet");
  console.log(`Hello ${nameToGreet}!`);
  const token = process.env.ACTIONS_RUNTIME_TOKEN;
  const Github = getOctokit(token);
  const time = new Date().toTimeString();
  setOutput("time", time);
  // Get the JSON webhook payload for the event that triggered the workflow
  // const payload = JSON.stringify(context.payload, undefined, 2);
  // console.log(`The event payload: ${payload}`);
  
  Github.log.info("testing1");
  Github.log.debug("testing2");
  test(Github);
  
} catch (error) {
  setFailed(error.message);
}

// from github import Github

// import base64
// from collections import namedtuple
// import config
// import frontmatter
// import json
// import logging
// import os
// import re
// import webapp2

// const config = { GITHUB_ACCESS_TOKEN: "placeholder" };

// const FILE_RE = new RegExp("^EIPS/eip-(d+).md$");
// const AUTHOR_RE = new RegExp("[(<]([^>)]+)[>)]");
// const MERGE_MESSAGE = `
// Hi, I'm a bot! This change was automatically merged because:
//  - It only modifies existing Draft, Review, or Last Call EIP(s)
//  - The PR was approved or written by at least one author of each modified EIP
//  - The build is passing
// `;


// type UnPromisify<T> = T extends Promise<infer U> ? U : T;
// type PR = UnPromisify<ReturnType<typeof Github.pulls.get>>;

// type CompareCommits = UnPromisify<ReturnType<typeof Github.repos.compareCommits>>;
// var _compared_: CompareCommits;
// type Files = typeof _compared_.data.files;
// var _files_: Files;
// type File = typeof _files_[0];


// const EIPInfo = { EIPInfo: ["number", "authors"] };

// let users_by_email = {};

// const find_user_by_email = (email: string) => {
//   if (!users_by_email[email]) {
//     const results = Github.search_users(email);
//     if (results.length > 0) {
//       console.log("Recording mapping from %s to %s", email, results[0].login);
//       users_by_email[email] = "@" + results[0].login;
//     } else {
//       console.log("No github user found for %s", email);
//     }
//   } else return users_by_email[email];
// };

// const ALLOWED_STATUSES = new Set(["draft", "last call", "review"]);

// const request = await Github.repos.compareCommits({
//   base: context.payload.pull_request?.base?.sha,
//   head: context.payload.pull_request?.head?.sha,
//   owner: context.repo.owner,
//   repo: context.repo.repo
// })

// // class MergeHandler(webapp2.RequestHandler):

// const resolve_author = (author: string) => {
//   if (author[0] === "@") {
//     return author.toLowerCase();
//   } else {
//     // Email address
//     return (find_user_by_email(author) || author).toLowerCase();
//   }
// };

// const get_authors = (authorlist: string[]) => {
//   const authors = authorlist.map((author) => author.match(AUTHOR_RE));
//   return new Set(authors.map(resolve_author));
// };

// const check_file = ({data: pr}: PR, file: File) => {
//   const fileName: string = file.filename;
  
//   try {
//     const match = fileName.search(FILE_RE);
//     if (!match) {
//       return [null, `File ${fileName} is not an EIP`];
//     }

//     const eipnum = match[0];

//     if (file.status == "added") {
//       return [null, `Contains new file ${fileName}`];
//     }

//     Github.log.info(
//       `Getting file ${fileName} from ${pr.base.user.login}@${pr.base.repo.name}/${pr.base.sha}`
//     );
//     const base = pr.base.repo.get_contents(file.filename, pr.base.sha);
//     const basedata = frontmatter(btoa(base.content));

//     const status = basedata.attributes["status"];
//     const author = basedata.attributes["author"];
//     if (ALLOWED_STATUSES.has(status.toLowerCase())) {
//       return [
//         null,
//         `EIP ${eipnum} is in state ${status}, not Draft or Last Call`,
//       ];
//     }
//     const eip = EIPInfo(eipnum, get_authors(author));

//     if (basedata.attributes["eip"] !== eipnum) {
//       return [
//         eip,
//         `EIP header in ${fileName} does not match: ${basedata.attributes["eip"]}`,
//       ];
//     }

//     Github.log.info(
//       "`Getting file ${fileName} from ${pr.base.user.login}@${pr.base.repo.name}/${pr.base.sha}`"
//     );
//     const head = pr.head.repo.get_contents(file.filename, pr.head.sha); // ref=pr.head.sha
//     const headdata = frontmatter(btoa(head.content));
//     if (headdata.attributes["eip"] != eipnum) {
//       return [
//         eip,
//         `EIP header in modified file ${fileName} does not match: ${headdata.attributes["eip"]}`,
//       ];
//     } else if (
//       headdata.attributes["status"].toLowerCase() !=
//       basedata.attributes["status"].toLowerCase()
//     ) {
//       return [
//         eip,
//         `Trying to change EIP ${eipnum} state from ${basedata.attributes["status"]} to ${headdata.attributes["status"]}`,
//       ];
//     }

//     return [eip, null];
//   } catch (e) {
//     console.error("Exception checking file %s", file.filename);
//     return [null, `Error checking file ${file.filename}`];
//   }
// };

// const post = () => {
//   const payload = JSON.parse(request["payload"]);
//   if (request.headers.includes("X-Github-Event")) {
    
//     const event = request.headers["X-Github-Event"];
//     Github.log.info(`Got Github webhook event ${event}`);
//     if (event == "pull_request_review") {
//       const pr = payload["pull_request"];
//       const prnum = pr["number"];
//       const repo = pr["base"]["repo"]["full_name"];
//       Github.log.info("Processing review on PR ${repo}/${prnum}...");
//       check_pr(repo, prnum);
//     }
//   } else {
//     Github.log.info(`Processing build ${payload["number"]}...`);
//     if (payload["pull_request_number"] === null) {
//       Github.log.info(
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

// const get = () => {
//   return check_pr(request["repo"], JSON.parse(request["pr"]))
// }

// const get_approvals = (pr) => {
//   let approvals = '@' + pr.user.login.toLowerCase()
//   const reviews = pr.get_reviews()

//   reviews.map(review => {
//     if (review.state == "APPROVED") {
//       approvals += '@' + review.user.login.toLowerCase()
//     }
//   })
      
//   return approvals
// }

// const post_comment = async (pr: PR, message: string) => {
//   const me = Github.get_user()
//   const {data: comments} = await Github.issues.listComments();

//   // If comment already exists, edit that 
//   for (const comment of comments) {
//     if (comment.user.login == me.login) {
//       Github.log.info("Found comment by self");
//     } 
    
//     if (comment.body != message) {
//       Github.issues.updateComment({
//         owner: comment.user.login,
//         repo: pr.data.base.repo.full_name,
//         comment_id: comment.id,
//         body: message
//       })
//       return;
//     }
//   }
  
//   // if comment does not exist, create a new one
//   Github.issues.createComment({
//     owner: pr.data.base.repo.owner.login,
//     repo: pr.data.base.repo.full_name,
//     issue_number: pr.data.number,
//     body: message
//   })
// }

// const check_pr = async (reponame, prnum) => {
//     Github.log.info(`Checking PR ${prnum} on ${reponame}`)
//     const repos = await Github.search.repos(reponame);
//     const repo = repos.data.items.find(repo => repo.name === reponame);
//     const pr = await Github.pulls.get({repo: repo.full_name, owner: repo.owner.login, pull_number: prnum})
//     let response = "";

//     if ( pr.data.merged ) {
//       Github.log.info("PR %d is already merged; quitting", prnum)
//       return;
//     }
//     if (pr.data.mergeable_state != 'clean') {
//       Github.log.info(`PR ${prnum} mergeable state is ${pr.data.mergeable_state}; quitting`)
//       return;
//     }

//     const files = request.data.files;

//     let eips = []
//     let errors = []
//     files.map(file => {
//       const [eip, error] = check_file(pr, file)
//       if (eip){
//           eips.push(eip)
//       }
//       if (error) {
//         Github.log.info(error)
//         errors.push(error)
//       }
//     })

//     let reviewers = new Set()
//     const approvals = get_approvals(pr)
//     Github.log.info(`Found approvals for ${prnum}: ${approvals}`)
//     // TODO: define eip types
//     eips.map(eip => {
//       const authors: Set<string> = eip.authors;
//       const number: string = eip.number;
//       Github.log.info(`EIP ${number} has authors: ${authors}`);
//       if (authors.size == 0) {
//         errors.push(`EIP ${number} has no identifiable authors who can approve PRs`)
//       } else if ([...approvals].find(authors.has)){
//         errors.push(`EIP ${number} requires approval from one of (${authors})`);
//         [...authors].map(author => {
//           if (author.startsWith('@')) {
//             reviewers.add(author.slice(1))
//           }
//         })
//       }
//     })
        

//     if (errors.length === 0){
//       Github.log.info(`Merging PR ${prnum}!`);
//       response = `Merging PR ${prnum}!`;

//       const eipNumbers = eips.join(', ');
//       Github.pulls.merge({
//         pull_number: pr.data.number,
//         repo: pr.data.base.repo.full_name,
//         owner: pr.data.base.repo.owner.login,
//         commit_title: `Automatically merged updates to draft EIP(s) ${eipNumbers} (#${prnum})`,
//         commit_message: MERGE_MESSAGE,
//         merge_method: "squash",
//         sha: pr.data.head.sha
//       })
//     } else if (errors.length > 0 && eips.length > 0) {
//       let message = "Hi! I'm a bot, and I wanted to automerge your PR, but couldn't because of the following issue(s):\n\n"
//       message += errors.join("\n - ");

//       post_comment(pr, message)
//     }



// // app = webapp2.WSGIApplication([
// //     ('/merge/', MergeHandler),
// // ], debug=True)
