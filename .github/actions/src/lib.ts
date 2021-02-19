import { File, Github, PR } from "./types";
import frontmatter from "front-matter";

const FILE_RE = new RegExp("^EIPS/eip-(d+).md$");
const AUTHOR_RE = new RegExp("[(<]([^>)]+)[>)]");
const MERGE_MESSAGE = `
Hi, I'm a bot! This change was automatically merged because:
 - It only modifies existing Draft, Review, or Last Call EIP(s)
 - The PR was approved or written by at least one author of each modified EIP
 - The build is passing
`;

// const EIPInfo = { EIPInfo: ["number", "authors"] };

let users_by_email = {};

// const find_user_by_email = (Github: Github) => (email: string) => {
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

// // class MergeHandler(webapp2.RequestHandler):

// const resolve_author = (Github: Github) => (author: string) => {
//   if (author[0] === "@") {
//     return author.toLowerCase();
//   } else {
//     // Email address
//     return (find_user_by_email(Github)(author) || author).toLowerCase();
//   }
// };

// const get_authors = (Github: Github) => (authorlist: string[]) => {
//   const authors = authorlist.map((author) => author.match(AUTHOR_RE));
//   return new Set(authors.map(resolve_author(Github)));
// };

// const check_file = (Github: Github) => ({data: pr}: PR, file: File) => {
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

//     console.log(
//       `Getting file ${fileName} from ${pr.base.user.login}@${pr.base.repo.name}/${pr.base.sha}`
//     );

//     const
//     const basedata = frontmatter(btoa());

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

//     console.log(
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

// const get_approvals = (pr: PR) => {
//   let approvals = '@' + pr.data.user.login.toLowerCase()
//   const reviews = pr.get_reviews()

//   reviews.map(review => {
//     if (review.state == "APPROVED") {
//       approvals += '@' + review.user.login.toLowerCase()
//     }
//   })
      
//   return approvals
// }

// const post_comment = (Github: Github) => async (pr: PR, message: string) => {
//   const me = Github.get_user()
//   const {data: comments} = await Github.issues.listComments();

//   // If comment already exists, edit that 
//   for (const comment of comments) {
//     if (comment.user.login == me.login) {
//       console.log("Found comment by self");
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

export const check_pr = (request: any, Github: Github) => async (reponame: string, prnum: number) => {
  console.log(`Checking PR ${prnum} on ${reponame}`)
  const repos = await Github.search.repos({q: reponame});
  console.log(`repos ${JSON.stringify(repos)}`)
  const repo = repos.data.items.find(repo => repo.name === reponame);
  console.log(`repo: ${repo}`)
  const pr = await Github.pulls.get({repo: repo.full_name, owner: repo.owner.login, pull_number: prnum})
  console.log(`pr: ${pr}`)
  let response = "";

  if ( pr.data.merged ) {
    console.log("PR %d is already merged; quitting", prnum)
    return;
  }
  if (pr.data.mergeable_state != 'clean') {
    console.log(`PR ${prnum} mergeable state is ${pr.data.mergeable_state}; quitting`)
    return;
  }

  const files = request.data.files;

  let eips = []
  let errors = []
  console.log(files || "no files")
  // files.map(file => {
  //   const [eip, error] = check_file(Github)(pr, file)
  //   if (eip){
  //       eips.push(eip)
  //   }
  //   if (error) {
  //     console.log(error)
  //     errors.push(error)
  //   }
  // })

  let reviewers = new Set()
  // const approvals = get_approvals(pr)
  // console.log(`Found approvals for ${prnum}: ${approvals}`)
 
  eips.map(eip => {
    const authors: Set<string> = eip.authors;
    const number: string = eip.number;
    console.log(`EIP ${number} has authors: ${authors}`);
    if (authors.size == 0) {
      errors.push(`EIP ${number} has no identifiable authors who can approve PRs`)
    }// } else if ([...approvals].find(authors.has)){
    //   errors.push(`EIP ${number} requires approval from one of (${authors})`);
    //   [...authors].map(author => {
    //     if (author.startsWith('@')) {
    //       reviewers.add(author.slice(1))
    //     }
    //   })
    // }
  })
      

  if (errors.length === 0){
    console.log(`Merging PR ${prnum}!`);
    response = `Merging PR ${prnum}!`;

    const eipNumbers = eips.join(', ');
    Github.pulls.merge({
      pull_number: pr.data.number,
      repo: pr.data.base.repo.full_name,
      owner: pr.data.base.repo.owner.login,
      commit_title: `Automatically merged updates to draft EIP(s) ${eipNumbers} (#${prnum})`,
      commit_message: MERGE_MESSAGE,
      merge_method: "squash",
      sha: pr.data.head.sha
    })
  } else if (errors.length > 0 && eips.length > 0) {
    let message = "Hi! I'm a bot, and I wanted to automerge your PR, but couldn't because of the following issue(s):\n\n"
    message += errors.join("\n - ");

    console.log(`posting comment: ${message}`)
    // post_comment(Github)(pr, message)
  }
}
