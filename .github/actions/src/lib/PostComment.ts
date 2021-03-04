import { getOctokit } from "@actions/github";
import { context } from "@actions/github";
import { COMMENT_HEADER, GITHUB_TOKEN, PostComment } from "src/utils";

export const postComment = async ({ errors, pr, eips }: PostComment) => {
  const Github = getOctokit(GITHUB_TOKEN);
  const message = COMMENT_HEADER + errors.join("\n\t\t - ");

  console.log(`------- Posting Comment`);
  console.log(`\t- comment body:\n\t\t"""\n\t\t${message}\n\t\t"""`);

  const { data: me } = await Github.users.getAuthenticated();
  console.log(`\t- Got user ${me.login}`);
  const { data: comments } = await Github.issues.listComments({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.issue.number
  });
  console.log(
    `\t- Found issue number ${context.issue.number} with ${comments.length} comments associated with it`
  );

  // If comment already exists, edit that
  for (const comment of comments) {
    if (comment.user?.login == me.login) {
      console.log("\t- Found comment by self (github bot)");

      console.log(
        `\t- Current comment body:\n\t\t"""\n\t\t${comment.body}\n\t\t"""`
      );
      if (comment.body != message) {
        console.log(`\t- Comment differs from current errors, so updating...`);
        Github.issues
          .updateComment({
            owner: context.repo.owner,
            repo: context.repo.repo,
            comment_id: comment.id,
            body: message
          })
          .catch((err) => {
            console.log(err);
          });
        return;
      }

      console.log(`\t- No change in error comment; quiting...`);
      return;
    }
  }

  // if comment does not exist, create a new one
  console.log(`\t- Posting a new comment`);
  Github.issues.createComment({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.issue.number,
    body: message
  });
};
