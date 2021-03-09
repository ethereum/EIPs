import { getOctokit } from "@actions/github";
import { EipStatus } from "./Constants";
import { Endpoints } from "@octokit/types";

export type Github = ReturnType<typeof getOctokit>;
const Github = getOctokit("fake");

const CompareCommits = () =>
  Github.repos.compareCommits().then((res) => res.data);
export type CompareCommits = UnPromisify<ReturnType<typeof CompareCommits>>;

type UnPromisify<T> = T extends Promise<infer U> ? U : T;
const PR = () => Github.pulls.get().then((res) => res.data);
export type PR = UnPromisify<ReturnType<typeof PR>>;

const Commit = () => Github.repos.getCommit().then((res) => res.data);
export type Commit = UnPromisify<ReturnType<typeof Commit>>;

const Files = () => Github.repos.compareCommits().then((res) => res.data.files);
export type Files = UnPromisify<ReturnType<typeof Files>>;
const File = () =>
  Github.repos.compareCommits().then((res) => res.data.files[0]);
export type File = UnPromisify<ReturnType<typeof File>>;
const CommitFiles = () =>
  Github.repos.compareCommits().then((res) => res.data.base_commit.files);
export type CommitFiles = UnPromisify<ReturnType<typeof CommitFiles>>;
const CommitFile = () =>
  Github.repos
    .compareCommits()
    .then((res) => res.data.base_commit.files && res.data.base_commit.files[0]);
export type CommitFile = UnPromisify<ReturnType<typeof CommitFile>>;

const Repo = () => Github.repos.get().then((res) => res.data);
export type Repo = UnPromisify<ReturnType<typeof Repo>>;

// This was extracted directly from Octokit repo
// node_modules/@octokit/openapi-types/generated/types.ts : 7513 - 7553
export type ContentFile = {
  type: string;
  encoding: string;
  size: number;
  name: string;
  path: string;
  content: string;
  sha: string;
  url: string;
  git_url: string | null;
  html_url: string | null;
  download_url: string | null;
  _links: {
    git: string | null;
    html: string | null;
    self: string;
  };
  target?: string;
  submodule_git_url?: string;
};

export type ContentResponse = Endpoints["GET /repos/{owner}/{repo}/contents/{path}"]["response"]["data"];

export type EIP = {
  number: string;
  status: EipStatus;
  authors: Set<string>;
};
