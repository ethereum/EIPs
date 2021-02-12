import core from "@actions/core";
import github from "@actions/github";
// import Github from "github-api";

try {
  // `who-to-greet` input defined in action metadata file
  const nameToGreet = core.getInput("who-to-greet");
  console.log(`Hello ${nameToGreet}!`);
  const time = new Date().toTimeString();
  core.setOutput("time", time);
  // Get the JSON webhook payload for the event that triggered the workflow
  const payload = JSON.stringify(github.context.payload, undefined, 2);
  console.log(`The event payload: ${payload}`);
} catch (error) {
  core.setFailed(error.message);
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

const config = {"GITHUB_ACCESS_TOKEN": "placeholder"};

const FILE_RE = new RegExp("^EIPS/eip-(d+).md$");
const AUTHOR_RE = new RegExp("[(<]([^>)]+)[>)]");
const MERGE_MESSAGE = `
Hi, I'm a bot! This change was automatically merged because:
 - It only modifies existing Draft, Review, or Last Call EIP(s)
 - The PR was approved or written by at least one author of each modified EIP
 - The build is passing
`;

const Github = github.getOctokit(config.GITHUB_ACCESS_TOKEN)

const EIPInfo = {'EIPInfo': ['number', 'authors']};

let users_by_email = {};

const find_user_by_email = (email: string) => {
  if ( !users_by_email[email] ) {
    const results = Github.search_users(email)
    if ( results.length > 0) {
      console.log("Recording mapping from %s to %s", email, results[0].login)
      users_by_email[email] = '@' + results[0].login
    } else {
      console.log("No github user found for %s", email)
    }
  } else return users_by_email[email]
}

const ALLOWED_STATUSES = new Set(['draft', 'last call', 'review'])

// class MergeHandler(webapp2.RequestHandler):
  const resolve_author = (author: string) => {
    if (author[0] === '@') {
      return author.toLowerCase()
    } else {
      // Email address
      return (find_user_by_email(author) || author).toLowerCase()
    }
  }

  const get_authors = (authorlist: string[]) => {
    const authors = authorlist.map(author => author.match(AUTHOR_RE));
    return new Set(authors.map(resolve_author))
  }

    // def check_file(self, pr, file):
    //     try:
    //         match = FILE_RE.search(file.filename)
    //         if not match:
    //             return (None, "File %s is not an EIP" % (file.filename,))
    //         eipnum = int(match.group(1))

    //         if file.status == "added":
    //             return (None, "Contains new file %s" % (file.filename,))

    //         logging.info("Getting file %s from %s@%s/%s", file.filename, pr.base.user.login, pr.base.repo.name, pr.base.sha)
    //         base = pr.base.repo.get_contents(file.filename, ref=pr.base.sha)
    //         basedata = frontmatter.loads(base64.b64decode(base.content))
    //         if basedata.get("status").lower() not in ALLOWED_STATUSES:
    //             return (None, "EIP %d is in state %s, not Draft or Last Call" % (eipnum, basedata.get("status")))

    //         eip = EIPInfo(eipnum, self.get_authors(basedata.get("author")))

    //         if basedata.get("eip") != eipnum:
    //             return (eip, "EIP header in %s does not match: %s" % (file.filename, basedata.get("eip")))

    //         logging.info("Getting file %s from %s@%s/%s", file.filename, pr.head.user.login, pr.head.repo.name, pr.head.sha)
    //         head = pr.head.repo.get_contents(file.filename, ref=pr.head.sha)
    //         headdata = frontmatter.loads(base64.b64decode(head.content))
    //         if headdata.get("eip") != eipnum:
    //             return (eip, "EIP header in modified file %s does not match: %s" % (file.filename, headdata.get("eip")))
    //         if headdata.get("status").lower() != basedata.get("status").lower():
    //             return (eip, "Trying to change EIP %d state from %s to %s" % (eipnum, basedata.get("status"), headdata.get("status")))

    //         return (eip, None)
    //     except Exception, e:
    //         logging.exception("Exception checking file %s", file.filename)
    //         return (None, "Error checking file %s" % (file.filename,))

    // def post(self):
    //     payload = json.loads(self.request.get("payload"))
    //     if 'X-Github-Event' in self.request.headers:
    //         event = self.request.headers['X-Github-Event']
    //         logging.info("Got Github webhook event %s", event)
    //         if event == "pull_request_review":
    //             pr = payload["pull_request"]
    //             prnum = int(pr["number"])
    //             repo = pr["base"]["repo"]["full_name"]
    //             logging.info("Processing review on PR %s/%d...", repo, prnum)
    //             self.check_pr(repo, prnum)
    //     else:
    //         logging.info("Processing build %s...", payload["number"])
    //         if payload.get("pull_request_number") is None:
    //             logging.info("Build %s is not a PR build; quitting", payload["number"])
    //             return
    //         prnum = int(payload["pull_request_number"])
    //         self.check_pr(payload["repository"]["owner_name"] + "/" + payload["repository"]["name"], prnum)

    // def get(self):
    //     self.check_pr(self.request.get("repo"), int(self.request.get("pr")))

    // def get_approvals(self, pr):
    //     approvals = ['@' + pr.user.login.lower()]
    //     for review in pr.get_reviews():
    //         if review.state == "APPROVED":
    //             approvals.append('@' + review.user.login.lower())
    //     return approvals

    // def check_pr(self, reponame, prnum):
    //     logging.info("Checking PR %d on %s", prnum, reponame)
    //     repo = github.get_repo(reponame)
    //     pr = repo.get_pull(prnum)
    //     if pr.merged:
    //         logging.info("PR %d is already merged; quitting", prnum)
    //         return
    //     if pr.mergeable_state != 'clean':
    //         logging.info("PR %d mergeable state is %s; quitting", prnum, pr.mergeable_state)
    //         return

    //     eips = []
    //     errors = []
    //     for file in pr.get_files():
    //         eip, error = self.check_file(pr, file)
    //         if eip is not None:
    //             eips.append(eip)
    //         if error is not None:
    //             logging.info(error)
    //             errors.append(error)

    //     reviewers = set()
    //     approvals = self.get_approvals(pr)
    //     logging.info("Found approvals for %d: %r", prnum, approvals)
    //     for eip in eips:
    //         logging.info("EIP %d has authors: %r", eip.number, eip.authors)
    //         if len(eip.authors) == 0:
    //             errors.append("EIP %d has no identifiable authors who can approve PRs" % (eip.number,))
    //         elif eip.authors.isdisjoint(approvals):
    //             errors.append("EIP %d requires approval from one of (%s)" % (eip.number, ', '.join(eip.authors)))
    //             for author in eip.authors:
    //                 if author.startswith('@'):
    //                     reviewers.add(author[1:])

    //     if len(errors) == 0:
    //         logging.info("Merging PR %d!", prnum)
    //         self.response.write("Merging PR %d!" % (prnum,))
    //         pr.merge(
    //             commit_title="Automatically merged updates to draft EIP(s) %s (#%d)" % (', '.join('%s' % eip.number for eip in eips), prnum),
    //             commit_message=MERGE_MESSAGE,
    //             merge_method="squash",
    //             sha=pr.head.sha)
    //     elif len(errors) > 0 and len(eips) > 0:
    //         message = "Hi! I'm a bot, and I wanted to automerge your PR, but couldn't because of the following issue(s):\n\n"
    //         message += "\n".join(" - " + error for error in errors)

    //         self.post_comment(pr, message)

    // def post_comment(self, pr, message):
    //     me = github.get_user()
    //     for comment in pr.get_issue_comments():
    //         if comment.user.login == me.login:
    //             logging.info("Found comment by myself")
    //             if comment.body != message:
    //                 comment.edit(message)
    //             return
    //     pr.create_issue_comment(message)

// app = webapp2.WSGIApplication([
//     ('/merge/', MergeHandler),
// ], debug=True)
