import { getOctokit } from "@actions/github";
import { GITHUB_TOKEN, MERGE_MESSAGE } from "src/utils/constants";
import { PR, EIP } from "src/utils/types";

export type Merge = {
  pr: PR,
  eips: EIP[]
}
  
export const merge = async ({pr: _pr, eips}: Merge) => {
  const pr = _pr.data;
  const prNum = pr.number;
  const Github = getOctokit(GITHUB_TOKEN);
  const eipNumbers = eips.join(", ");
  
  console.log(`Merging PR ${pr.number}!`);
  await Github.pulls.merge({
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