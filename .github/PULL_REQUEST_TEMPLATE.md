**ATTENTION: ERC-RELATED PULL REQUESTS NOW OCCUR IN [ETHEREUM/ERCS](https://github.com/ethereum/ercs)**

--

When opening a pull request to submit a new EIP, please use the suggested template: https://github.com/ethereum/EIPs/blob/master/eip-template.md

We have a GitHub bot that automatically merges some PRs. It will merge yours immediately if certain criteria are met:

 - The PR edits only existing draft PRs.
 - The build passes.
 - Your GitHub username or email address is listed in the 'author' header of all affected PRs, inside <triangular brackets>.
 - If matching on email address, the email address is the one publicly listed on your GitHub profile.

If your PR is green but still will not merge:

 - Check the labels. Process labels such as `e-consensus` or `e-review` mean an editor still has to act.
 - Changes under `.github/workflows/**` are owned by the governance editors, not the bot, so they need a human review.
 - A PR that mixes an EIP with tooling or workflow changes needs sign-off from both, which is usually slower than splitting it in two.
