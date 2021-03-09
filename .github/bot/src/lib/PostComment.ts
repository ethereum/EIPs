import { getOctokit } from "@actions/github";
import { context } from "@actions/github";
import { COMMENT_HEADER, GITHUB_TOKEN, ERRORS } from "src/utils";

export const postComment = async () => {
  const Github = getOctokit(GITHUB_TOKEN);
  const message = COMMENT_HEADER + "\n\t - " + ERRORS.join("\n\t - ");

  const { data: me } = await Github.users.getAuthenticated();
  const { data: comments } = await Github.issues.listComments({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.issue.number
  });

  // If comment already exists, update it
  for (const comment of comments) {
    if (comment.user?.login == me.login) {
      if (comment.body != message) {
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
      }
      return;
    }
  }

  // else create a new one
  Github.issues.createComment({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.issue.number,
    body: message
  });
};
