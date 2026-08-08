**ATTENTION: ERC-RELATED PULL REQUESTS NOW OCCUR IN [ETHEREUM/ERCS](https://github.com/ethereum/ercs)**

--

When opening a pull request to submit a new EIP, please use the suggested template: https://github.com/ethereum/EIPs/blob/master/eip-template.md

We have a GitHub bot that automatically merges some PRs. It will merge yours immediately if certain criteria are met:

 - The PR edits only existing draft PRs.
 - The build passes.
 - Your GitHub username or email address is listed in the 'author' header of all affected PRs, inside <triangular brackets>.
 - If matching on email address, the email address is the one publicly listed on your GitHub profile.

If your PR is green but still blocked from merge:

 - Check labels on the PR. Certain process labels (for example `e-consensus`) may indicate editor action is still required.
 - For workflow changes under `.github/workflows/**`, request review from workflow CODEOWNERS (`@lightclient`, `@SamWilsn`, `@xinbenlv`, `@g11tech`, `@jochem-brouwer`).
 - If all checks pass and author requirements are met, ask maintainers to enable auto-merge or merge manually.
