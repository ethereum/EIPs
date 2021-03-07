import { getOctokit } from "@actions/github";
import frontmatter, { FrontMatterResult } from "front-matter";
import { EipStatus } from "./constants"

export type Github = ReturnType<typeof getOctokit>;
const Github = getOctokit("fake");

export type Request = UnPromisify<
  ReturnType<typeof Github.repos.compareCommits>
>;

type UnPromisify<T> = T extends Promise<infer U> ? U : T;
const PR =  () => Github.pulls.get().then(res => res.data);
export type PR = UnPromisify<ReturnType<typeof PR>>;

const Commit = () => Github.repos.getCommit().then(res => res.data);
export type Commit = UnPromisify<ReturnType<typeof Commit>>;

export type CompareCommits = UnPromisify<
  ReturnType<typeof Github.repos.compareCommits>
>;

const Files = () => Github.repos.compareCommits().then(res => res.data.files)
export type Files = UnPromisify<ReturnType<typeof Files>>;
const File = () => Github.repos.compareCommits().then(res => res.data.files[0])
export type File = UnPromisify<ReturnType<typeof File>>;
const CommitFiles = () => Github.repos.compareCommits().then(res => res.data.base_commit.files);
export type CommitFiles = UnPromisify<ReturnType<typeof CommitFiles>>;
const CommitFile = () => Github.repos.compareCommits().then(res => res.data.base_commit.files && res.data.base_commit.files[0]);
export type CommitFile = UnPromisify<ReturnType<typeof CommitFile>>;

export type ParsedFile = {
  path: string;
  name: string;
  status: string;
  content: FrontMatterResult<any>;
};

export type EIP = {
  number: string;
  authors: Set<string>;
};

export type PostComment = {
  errors: string[];
  pr: PR;
  eips: EIP[];
};

export type PrDiff = {
  head: { eipNum: number; status: EipStatus; authors: Set<string> };
  base: { eipNum: number; status: EipStatus; authors: Set<string> };
};
