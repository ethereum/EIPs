import { getOctokit, context } from "@actions/github";
import { GITHUB_TOKEN, MERGE_MESSAGE } from "src/utils";
import { assertPr } from "./Assertions";
import { FileDiff } from "./GetFileDiff";

export const merge = async (diffs: FileDiff[]) => {
  const pr = await assertPr();
  const Github = getOctokit(GITHUB_TOKEN);
  const eips = diffs.map((diff) => diff.head.eipNum);
  const eipNumbers = eips.join(", ");

  await Github.pulls.merge({
    pull_number: pr.number,
    repo: context.repo.repo,
    owner: context.repo.owner,
    commit_title: `Automatically merged updates to draft EIP(s) ${eipNumbers} (#${pr.number})`,
    commit_message: MERGE_MESSAGE,
    merge_method: "squash",
    sha: pr.head.sha
  });

  return {
    response: `Merging PR ${pr.number}!`
  };
};
