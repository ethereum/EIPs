export const MERGE_MESSAGE = `
    Hi, I'm a bot! This change was automatically merged because:
    - It only modifies existing Draft, Review, or Last Call EIP(s)
    - The PR was approved or written by at least one author of each modified EIP
    - The build is passing
    `;
export const ALLOWED_STATUSES = new Set(["draft", "last call", "review"]);
export const COMMENT_HEADER =
  "Hi! I'm a bot, and I wanted to automerge your PR, but couldn't because of the following issue(s):\n\n";
export const GITHUB_TOKEN = process.env.GITHUB_TOKEN || "";

export enum FrontMatterAttributes {
  status = "status",
  eip = "eip",
  author = "author"
}

export enum EipStatus {
  draft = "draft"
}

export enum FileStatus {
  added = "added"
}

export enum EVENTS {
  pullRequest = "pull_request"
}
